--[[

Copyright (c) 2011-2015 chukong-inc.com

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

local next = next
local type = type
local tostring = tostring
local ngx = ngx
local ngx_on_abort = ngx.on_abort
local ngx_exit = ngx.exit
local ngx_thread_spawn = ngx.thread.spawn
local req_get_headers = ngx.req.get_headers
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format

local WebSocketsServerBase = class("WebSocketsServerBase", import(".ServerAppBase"))

WebSocketsServerBase.WEBSOCKETS_READY_EVENT = "WEBSOCKETS_READY_EVENT"
WebSocketsServerBase.WEBSOCKETS_CLOSE_EVENT = "WEBSOCKETS_CLOSE_EVENT"

function WebSocketsServerBase:ctor(config)
    WebSocketsServerBase.super.ctor(self, config)

    self._requestType = "websockets"

    self.config.websocketsTimeout = self.config.websocketsTimeout or 10 * 1000
    self.config.websocketsMaxPayloadLen = self.config.websocketsMaxPayloadLen or 16 * 1024
    self.config.websocketsMessageFormat = self.config.websocketsMessageFormat or "json"

    self._subscribeBroadcastChannelEnabled = false
    self._subscribeRetryCount = 1

    local ok, err = ngx_on_abort(function()
        self:dispatchEvent({name = ServerAppBase.CLIENT_ABORT_EVENT})
    end)
    if not ok then
        printInfo("WebSocketsServerBase:ctor() - failed to register the on_abort callback, ", err)
    end
end

function WebSocketsServerBase:runEventLoop()
    -- verify session token
    local tag, err = self:processWebSocketsSession() 
    if not tag then
        printWarn("WebSocketsServerBase:runEventLoop() - processWebSocketSession failed: %s", err) 
        return ngx.HTTP_UNAUTHORIZED
    end
    self._tag = tag

    -- create websocket connection
    local server = require("resty.websocket.server")
    local wb, err = server:new({
        timeout = self.config.websocketsTimeout,
        max_payload_len = self.config.websocketsMaxPayloadLen,
    })
    if not wb then
        printWarn("WebSocketsServerBase:runEventLoop() - failed to create websocket connection: %s", err)
        return ngx.HTTP_SERVICE_UNAVAILABLE
    end
    self._websocket = wb

    --  client tag is bound to this websocket id 
    self:setSidTag(tag)

    -- spawn a thread to subscribe redis channel for broadcast
    local ok, err = self:subscribeBroadcastChannel()
    if not ok then
        printWarn("WebSocketsServerBase:runEventLoop() - failed to subscribe broadcast channel: %s", err)
        return ngx.HTTP_SERVICE_UNAVAILABLE
    end

    local ret = ngx.HTTP_OK
    local retryCount = 0
    local maxRetryCount = self.config.maxWebsocketRetryCount
    local serialData = {} 

    -- event loop
    while true do
        local data, typ, err = wb:recv_frame()
        if not data then
            printWarn("WebSocketsServerBase:runEventLoop() - failed to receive frame, %s", err)
            if err and retryCount < maxRetryCount then
                retryCount = retryCount + 1
                goto recv_next_message
            end
            ret = ngx.HTTP_INTERNAL_SERVER_ERROR
            break
        end

        if err == "again" then 
            table_insert(serialData, data)
            goto recv_next_message
        end

        if next(serialData) ~= nil then
            data = table_concat(serialData)
            serialData = {} 
        end

        if typ == "close" then
            break -- exit event loop
        elseif typ == "ping" then
            -- send pong
            local bytes, err = wb:send_pong()
            if not bytes then
                printWarn("WebSocketsServerBase:runEventLoop() - failed to send pong, %s", err)
            end
        elseif typ == "pong" then
            printInfo("WebSocketsServerBase:runEventLoop() - client ponged")
        elseif typ == "text" then
            local ok, err = self:processWebSocketsMessage(data, typ)
            if not ok then
                printWarn("WebSocketsServerBase:runEventLoop() - process text message failed: %s", err)
            end
        elseif typ == "binary" then
            local ok, err = self:processWebSocketsMessage(data, typ)
            if not ok then
                printWarn("WebSocketsServerBase:runEventLoop() - process binary message failed: %s", err)
            end
        else
            printInfo("WebSocketsServerBase:runEventLoop() - unknwon message type %s", tostring(typ))
        end

::recv_next_message::

    end -- while

    -- end the subscribe thread
    self:unsubscribeBroadcastChannel()

    -- unbind socket id
    self:unsetSidTag(self._tag)

    -- close connection
    wb:send_close()
    self._websockets = nil

    return ret
end

function WebSocketsServerBase:processWebSocketsMessage(rawMessage, messageType)
    if messageType ~= "text" then
        return false, string_format("not supported message type %s", messageType)
    end

    local ok, message = self:parseWebSocketsMessage(rawMessage)
    if not ok then
        return false, message
    end

    local msgid = message.msg_id
    local actionName = message.action

    local result = self:doRequest(actionName, message)
    if type(result) == "table" then
        if msgid then
            result.msg_id = msgid
        else
            printInfo("WebSocketsServerBase:processWebSocketsMessage() - unidentified result from action %s", actionName)
            result = nil
        end
    elseif result ~= nil then
        if msgid then
            printInfo("WebSocketsServerBase:processWebSocketsMessage() - invalid result from action %s for message %s", actionName, msgid)
            result = {error = result}
        else
            printInfo("WebSocketsServerBase:processWebSocketsMessage() - invalid and unidentified result from action %s", actionName)
            result = nil
        end
    end

    if not self._websockets then
        return false, "websockets removed"
    end

    if result then
        local bytes, err = self._websockets:send_text(json.encode(result))
        if not bytes then
            return false, err
        end
    end

    return true
end

function WebSocketsServerBase:parseWebSocketsMessage(rawMessage)
    if self.config.websocketsMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return true, message
        else
            return false, string_format("invalid message format %s", tostring(rawMessage))
        end
    else
        return false, string_format("not support message format %s", tostring(self.config.websocketsMessageFormat))
    end
end

function WebSocketsServerBase:processWebSocketsSession()
    -- read http handshake headers
    local headers = req_get_headers()
    if not headers["quick_server_token"]  then
        printWarn("WebSocketsServerBase:processWebSocketSession() - client don't send session token via header")
        return nil, "client don't send session token via header"
    end

    if not headers["client_tag"] then
        printWarn("WebSocketsServerBase:processWebSocketSession() - client don't send tag via header")
        return nil, "client don't send session token via header"
    end

    local data = {}
    data.token = headers["quick_server_token"]
    data.tag = headers["client_tag"]
    
    return self:checkSessionId(data) 
end

function WebSocketsServerBase:unsubscribeBroadcastChannel()
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    -- once this WebSocketServerApp receives "QUIT" from channel.quit, message loop will be ended.
    local ok, err = redis:command("publish", self.internalChannel, "QUIT")
    if not ok then
        printWarn("WebSocketsServerBase:unsubscribeBroadcastChannel() - publish QUIT failed: %s", err)
    end
    redis:close()
end

function WebSocketsServerBase:subscribeBroadcastChannel()
    if self._subscribeBroadcastChannelEnabled then
        printWarn("WebSocketServerApp:subscribeBroadcastChannel() - failed: already subscribed")
        return nil, "already subscribed" 
    end

    local internalChannel = self.internalChannel 

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()

    local function subscribe()
        self._subscribeBroadcastChannelEnabled = true
        local isRunning = true

        local loop, err = redis:pubsub({subscribe=internalChannel})
        if not loop then
            printError("WebSocketsServerBase, subscribe thread - redis subscribe channel failed: %s", err)
            ngx_exit(ngx.HTTP_SERVICE_UNAVAILABLE)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                printInfo("WebSocketsServerBase, subscribe thread - subscribed channel(%s), socket id: %d", msg.channel, self.socketId)
            elseif msg.kind == "message" then
                local payload = msg.payload
                printInfo("WebSocketsServerBase, subscribe thread - get msg from channel(%s), socket id: %d, msg: %s", msg.channel, self.socketId, payload)
                if payload == "QUIT" then
                    abort() 
                    isRunning = false
                    break
                end
                self.websockets:send_text(payload)
            end
        end

        -- when error occured or exit normally, 
        -- connect will auto close, channel will be unsubscribed
        redis:close()
        redis = nil

        self._subscribeBroadcastChannelEnabled = false

        printInfo("WebSocketsServerBase, subscribe thread - quit from subscribe loop, socketId = %d", self.socketId)
        printInfo("--------- SUBSCRIBE THREAD QUIT ----------")

        -- if an error leads to an exiting, retry to subscribe channel 
        if isRunning and self._subscribeRetryCount < self.config.maxSubscribeRetryCount then
            self._subscribeRetryCount = self._subscribeRetryCount + 1
            self:subscribeBroadcastChannel()
        end
    end
    ngx_thread_spawn(subscribe)

    return true, nil
end

return WebSocketsServerBase
