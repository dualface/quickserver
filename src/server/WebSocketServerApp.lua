local WebSocketServerApp = class("WebSocketServerApp", cc.server.WebSocketsServerBase)

local webSocketUidKey = "websocket_uid_key_"

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    if self.config.debug then
        printInfo("---------------- START -----------------")
    end

    self:addEventListener(WebSocketServerApp.WEBSOCKETS_READY_EVENT, self.onWebSocketsReady, self)
    self:addEventListener(WebSocketServerApp.WEBSOCKETS_CLOSE_EVENT, self.onWebSocketsClose, self)
    self:addEventListener(WebSocketServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)

    self.redis = cc.load("redis").service.new(config.redis)
    redis:connect()
   
    local ok, err = redis:command("INCR", webSocketUidKey)
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, err)
    end
    self.webSocketUid = ok

    self.chatChannel = string.format(config.chatChannelPattern, ok / 1000)
    self.jobChannel = string.format(config.jobChannelPattern, ok / 100)
    self.quitChannel = "channel.quit"
    self.subscribeMessageChannelEnabled = false 
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

---- events callback

function WebSocketServerApp.onWebSocketsReady(event)
    local self = event.tag
    self:subscribePushMessageChannel()
end

function WebSocketServerApp.onWebSocketsClose(event)
    local self = event.tag
    self:unsubscribePushMessageChannel()
end

function WebSocketServerApp.onClientAbort(event)
    local self = event.tag
    self:unsubscribePushMessageChannel()
end


---- internal methods

function WebSocketServerApp:subscribePushMessageChannel()
    assert(type(self.uid) == "string" and self.uid ~= "", "WebSocketServerApp:subscribePushMessageChannel() - invalid uid")
    assert(self.subscribeMessageChannelEnabled ~= true, "WebSocketServerApp:subscribePushMessageChannel() - already subscribed")

    local chatChannel = self.chatChannel
    local jobChannel = self.jobChannel 
    local quitChannel = self.quitChannel

    local chat_id = 1

    -- subscribe
    local function subscribe()
        self.subscribeMessageChannelEnabled = true
        local isRunning = true

        local redis = self.redis
        local loop, err = redis:pubsub({subscribe = {jobChannel, chatChannel, quitChannel}})
        if err then
            throw(ERR_SERVER_OPERATION_FAILED, "subscribe channel [%s, %s] failed, %s", jobChannel, chatChannel, err)
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
                    printInfo("get message [%s] from channel [%s]", msg_, msg.channel)
                end

                local payload = msg.payload
                local channel = msg.channel
                if channel == quitChannel then
                    local uid = tonumber(string.sub(payload, 6))
                    if uid == self.websocketUid then
                        isRunning = false
                        abort()
                        break
                    end
                elseif channel == chatChannel then  
                    local reply = {}
                    local r = json.decode(payload)
                    if type(r) ~= "table" then
                        reply.err_msg = "invalid chat message is received."
                    else
                        reply.time = ngx.localtime() 
                        reply.chat_id = chat_id
                        reply.payload = r.payload
                        reply.nickname = r.nickname

                        chat_id = chat_id + 1
                    end
                    self.websockets:send_text(json.encode(reply))
                elseif channel == jobChannel then
                    local reply = {}
                    local r = json.decode(payload)
                    if type(r) ~= "table" then
                        reply.err_msg = "invalid job message is received."
                        self.websockets:send_text(json.encode(reply))
                    elseif r.sender_id == self.webSocketUid then 
                        reply.job_id = r.job_id
                        reply.payload = r.payload
                        reply.start_time = r.start_time
                        reply.end_time = ngx.localtime()
                        self.websockets:send_text(json.encode(reply))
                    end
                end
            end
        end

        -- when error occured, connect will auto close, subscribe will remove too
        redis:close()
        redis = nil

        if self.config.debug then
            printInfo("unsubscribed from channel [%s], sessid = %d", channel, self.sessionId)
            printInfo("----------------- QUIT -----------------")
        end

        self.subscribeMessageChannelEnabled = false

        if isRunning then
            self:subscribePushMessageChannel()
        end
    end

    ngx.thread.spawn(subscribe)
end

function WebSocketServerApp:unsubscribePushMessageChannel()
    local redis = self.redis

    -- once this WebSocketServerApp receives "QUIT" from channel.quit, message loop will be ended.
    redis:command("publish", self.quitChannel, "QUIT-" .. self.webSocketUid)
end

return WebSocketServerApp
