--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local WebSocketServerApp = class("WebSocketServerApp", cc.server.WebSocketsServerBase)

local websocketUidKey = "websocket_uid_key_"

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    if self.config.debug then
        printInfo("---------------- START -----------------")
    end

    self:addEventListener(WebSocketServerApp.WEBSOCKETS_READY_EVENT, self.onWebSocketsReady, self)
    self:addEventListener(WebSocketServerApp.WEBSOCKETS_CLOSE_EVENT, self.onWebSocketsClose, self)
    self:addEventListener(WebSocketServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)

    local redis = cc.load("redis").service.new(config.redis)
    redis:connect()
    local ok, err = redis:command("INCR", websocketUidKey)
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, "Generate websocketUid failed: %s", err)
    end
    redis:close()
    self.websocketUid = ok

    self.internalChannel = string.format("channel.%s", self.websocketUid)
    self.subscribeMessageChannelEnabled = false
    self.subscribeRetryCount = 1
    -- self.chatId = 1
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

    -- verify session id process
    local ok, err= self:processWebSocketSession()
    if not ok then
        printError("verify session id failed: %s", err)
        self.isSessionVerified = false
    else 
        self.isSessionVerified = true
    end

    -- tie this tag to current socket id

    -- subscribe a channel for broadcast
    self:subscribePushMessageChannel_()
end

function WebSocketServerApp.onWebSocketsClose(event)
    local self = event.tag
    self:unsubscribePushMessageChannel_()

    printInfo("---------------- QUIT -----------------")
end

function WebSocketServerApp.onClientAbort(event)
end


---- internal methods

function WebSocketServerApp:subscribePushMessageChannel_()
    if self.subscribeMessageChannelEnabled then
        printInfo("WebSocketServerApp:subscribePushMessageChannel_() - already subscribed")
        return nil
    end

    local internalChannel = self.internalChannel

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()

    local function subscribe_()
        self.subscribeMessageChannelEnabled = true
        local isRunning = true

        local loop, err = redis:pubsub(internalChannel)
        if err then
            throw(ERR_SERVER_OPERATION_FAILED, "subscribe channel [%s, %s] failed: %s", jobChannel, chatChannel, err)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                printInfo("subscribed channel [%s], websocketUid = %d", msg.channel, self.websocketUid)
            elseif msg.kind == "message" then
                local payload = msg.payload
                printInfo("get msg from channel [%s], websocketUid = %d, msg = %s", msg.channel, self.websocketUid, payload)
                if tonumber(string.sub(payload, 6)) == self.websocketUid then
                    abort() 
                    isRunning = false
                    break
                end
                self.websockets:send_text(payload)
            end
        end

        -- when error occured, connect will auto close, subscribe will remove too
        redis:close()
        redis = nil

        printInfo("quit from subscribe loop, websocketUid = %d", self.websocketUid)
        printInfo("---------- SUBSCRIBE THREAD QUIT ----------")

        self.subscribeMessageChannelEnabled = false

        if isRunning and self.subscribeRetryCount < self.config.maxSubscribeRetryCount then
            self.subscribeRetryCount = self.subscribeRetryCount + 1
            self:subscribePushMessageChannel_()
        end
    end

    ngx.thread.spawn(subscribe_)
end

function WebSocketServerApp:unsubscribePushMessageChannel_()
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()

    -- once this WebSocketServerApp receives "QUIT" from channel.quit, message loop will be ended.
    local ok, err = redis:command("publish", self.quitChannel, "QUIT-" .. self.websocketUid)
    if not ok then
        printInfo("publish QUIT failed: err = %s", tostring(err))
    end

    redis:close()
end

return WebSocketServerApp
