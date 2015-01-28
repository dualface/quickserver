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

local WebSocketServerApp = class("WebSocketServerApp", cc.server.WebSocketServerBase)

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    printInfo("---------------- START -----------------")

    self:addEventListener(WebSocketServerApp.WEBSOCKET_READY_EVENT, self.onWebSocketReady, self)
    self:addEventListener(WebSocketServerApp.WEBSOCKET_CLOSE_EVENT, self.onWebSocketClose, self)
    self:addEventListener(WebSocketServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)

    self.subscribeMessageChannelEnabled = false
    self.subscribeRetryCount = 1
end

function WebSocketServerApp:doRequest(actionName, data)
    printInfo("ACTION >> call [%s]", actionName)

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

    if DEBUG > 1 then
        local j = json.encode(result)
        printInfo("ACTION << ret  [%s] = (%d bytes) %s", actionName, string.len(j), j)
    end

    return result
end

---- events callback

function WebSocketServerApp.onWebSocketReady(event)
    local self = event.tag

    -- verify session id process
    local tag, err= self:processWebSocketSession()
    if not tag then
        printError("process websocket session failed: %s", err)
        self.isSessionVerified = false
        return
    end
    self.tag = tag
    self.isSessionVerified = true

    -- tie this tag to current socket id
    self:setSidTag(tag)

    -- subscribe a channel for broadcast
    self:subscribePushMessageChannel_()
end

function WebSocketServerApp.onWebSocketClose(event)
    local self = event.tag

    self:unsetSidTag(self.tag)

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

        local loop, err = redis:pubsub({subscribe=internalChannel})
        if err then
            throw(ServerAppBase.OPERATION_FAILED_ERROR, "subscribe channel(%s) failed: %s", internalChannel, err)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                printInfo("subscribed channel(%s), socket id: %d", msg.channel, self.socketId)
            elseif msg.kind == "message" then
                local payload = msg.payload
                printInfo("get msg from channel(%s), socket id: %d, msg: %s", msg.channel, self.socketId, payload)
                if payload == "QUIT" then
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

        printInfo("quit from subscribe loop, socketId = %d", self.socketId)
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
    local ok, err = redis:command("publish", self.internalChannel, "QUIT")
    if not ok then
        printInfo("publish QUIT failed: %s", err)
    end

    redis:close()
end

return WebSocketServerApp
