local WebSocketServerApp = class("WebSocketServerApp", cc.server.WebSocketsServerBase)

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    if self.config.debug then
        printInfo("---------------- START -----------------")
    end

    self:addEventListener(WebSocketServerApp.WEBSOCKETS_READY_EVENT, self.onWebSocketsReady, self)
    self:addEventListener(WebSocketServerApp.WEBSOCKETS_CLOSE_EVENT, self.onWebSocketsClose, self)
    self:addEventListener(WebSocketServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)
end

function WebSocketServerApp:doRequest(actionName, data)
    if self.config.debug then
        printInfo("ACTION >> call [%s]", actionName)
    end

    local _, result = xpcall(function()
                                 return WebSocketServerApp.super.doRequest(self, actionName, data)
                             end, 
                             function(err) 
                                 local beg, rear = string.find(err, "module.*not found") 
                                 if beg then 
                                     err = string.sub(err, beg, rear)
                                 end
                                 return {error = string.format([[Handle request failed: %s]], string.gsub(err, [[\]], ""))} 
                             end)

    if self.config.debug then
        local j = json.encode(result)
        printInfo("ACTION << ret  [%s] = (%d bytes) %s", actionName, string.len(j), j)
    end

    return result
end

function WebSocketServerApp:getUID()
    if not self.uid then
        throw(ERR_SERVER_INVALID_PARAMETERS, "not set uid")
    end
    return self.uid
end

function WebSocketServerApp:setUID(uid)
    self.uid = uid
end


---- events callback

function WebSocketServerApp:onWebSocketsReady(event)
end

function WebSocketServerApp:onWebSocketsClose(event)
    self:unsubscribePushMessageChannel()
end

function WebSocketServerApp:onClientAbort(event)
    self:unsubscribePushMessageChannel()
end


---- internal methods

function WebSocketServerApp:subscribePushMessageChannel()
    assert(type(self.uid) == "string" and self.uid ~= "", "WebSocketServerApp:subscribePushMessageChannel() - invalid uid")
    assert(self.subscribePushMessageChannelEnabled ~= true, "WebSocketServerApp:subscribePushMessageChannel() - already subscribed")

    -- subscribe
    self.onlineUsersChannel = string.format(ONLINE_USERS_CHANNEL_PATTERN, self.uid)

    local function subscribe()
        self.subscribePushMessageChannelEnabled = true

        local channel = self.onlineUsersChannel
        local isRunning = true

        local redis = self:newRedis()
        local loop, err = redis:pubsub({subscribe = channel})
        if err then
            throw(ERR_SERVER_OPERATION_FAILED, "subscribe channel [%s] failed, %s", channel, err)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                if self.config.debug then
                    printInfo("subscribed channel [%s], sessid = %d", msg.channel, self.sessionId)
                end
            elseif msg.kind == "message" then
                if self.config.debug then
                    local msg_ = msg.payload
                    if string.len(msg_) > 20 then
                        msg_ = string.sub(msg_, 1, 20) .. " ..."
                    end
                    printInfo("get message [%s] from channel [%s]", msg_, channel)
                end

                local cmd = string.sub(msg.payload, 1, 4)
                if cmd == "keep" then
                    local sessid = checkint(string.sub(msg.payload, 6))
                    if sessid ~= self.sessionId then
                        if self.websockets then
                            self.websockets:send_text(json.encode({name = "kick"}))
                            self:closeClientConnect() -- 关闭客户端连接
                        end
                    end
                elseif cmd == "quit" then
                    local sessid = checkint(string.sub(msg.payload, 6))
                    if sessid == self.sessionId then
                        isRunning = false
                        abort()
                        break
                    end
                else
                    -- forward message to client
                    self.websockets:send_text(msg.payload)
                end
            end
        end

        -- when error occured, connect will auto close, subscribe will remove too
        redis:close()
        redis = nil

        if self.config.debug then
            printInfo("unsubscribed from channel [%s], sessid = %d", channel, self.sessionId)
            print("----------------- QUIT -----------------")
        end

        self.subscribePushMessageChannelEnabled = false

        if isRunning then
            self:subscribePushMessageChannel()
        end
    end

    ngx.thread.spawn(subscribe)
end

function WebSocketServerApp:unsubscribePushMessageChannel()
    self:getRedis():command("publish", self.onlineUsersChannel, string.format("quit %d", self.sessionId))
end

return WebSocketServerApp
