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

local DEBUG = DEBUG
local type = type
local tostring = tostring
local ngx = ngx
local ngx_on_abort = ngx.on_abort
local ngx_exit = ngx.exit
local ngx_thread_spawn = ngx.thread.spawn
local req_read_body = ngx.req.read_body
local req_get_headers = ngx.req.get_headers
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format

local ServerAppBase = import(".ServerAppBase")

local WebSocketServerBase = class("WebSocketServerBase", ServerAppBase)

WebSocketServerBase.WEBSOCKET_READY_EVENT = "WEBSOCKET_READY_EVENT"
WebSocketServerBase.WEBSOCKET_CLOSE_EVENT = "WEBSOCKET_CLOSE_EVENT"

WebSocketServerBase.TEXT_MESSAGE_TYPE   = "text"
WebSocketServerBase.BINARY_MESSAGE_TYPE = "binary"

WebSocketServerBase.PROTOCOL_PATTERN = "quickserver: ([%w%d-]+)"

WebSocketServerBase.DEFAULT_TIME_OUT        = 10 * 1000 -- 10s
WebSocketServerBase.DEFAULT_MAX_PAYLOAD_LEN = 16 * 1024 -- 16KB
WebSocketServerBase.DEFAULT_MAX_RETRY_COUNT = 5 -- 5 times
WebSocketServerBase.DEFAULT_MESSAGE_FORMAT  = "json"

function WebSocketServerBase:ctor(config)
    WebSocketServerBase.super.ctor(self, config)

    self.config.websocketsTimeout       = self.config.websocketsTimeout or WebSocketServerBase.DEFAULT_TIME_OUT
    self.config.websocketsMaxPayloadLen = self.config.websocketsMaxPayloadLen or WebSocketServerBase.DEFAULT_MAX_PAYLOAD_LEN
    self.config.websocketsMaxRetryCount = self.config.websocketsMaxRetryCount or WebSocketServerBase.DEFAULT_MAX_RETRY_COUNT
    self.config.websocketsMessageFormat = self.config.websocketsMessageFormat or WebSocketServerBase.DEFAULT_MESSAGE_FORMAT

    self._requestType = "websockets"
    self._subscribeBroadcastChannelEnabled = false
    self._subscribeRetryCount = 1
end

function WebSocketServerBase:run()
    if not self:_authConnect() then
        error(string.format("WebSocketServerBase:run() - authConnect failed, %s", err))
    else
        self:dispatchEvent({name = ServerAppBase.APP_RUN_EVENT})
        self:runEventLoop()
        self:dispatchEvent({name = ServerAppBase.APP_QUIT_EVENT})
    end
end

function WebSocketServerBase:runEventLoop()
    local server = require("resty.websocket.server")
    local socket, err = server:new({
        timeout = self.config.websocketsTimeout,
        max_payload_len = self.config.websocketsMaxPayloadLen,
    })
    if err then
        error(string.format("WebSocketServerBase:runEventLoop() - failed to create websocket server, %s", err))
    end

    self._socket = socket
    self:dispatchEvent({name = WebSocketServerBase.WEBSOCKET_READY_EVENT})

    --  client tag is binding to this websocket id
    self:setSidTag(self._tag)

    -- spawn a thread to subscribe redis channel for broadcast
    local ok, err = self:_subscribeBroadcastChannel()
    if err then
        error(string.format("WebSocketServerBase:runEventLoop() - failed to subscribe broadcast channel: %s", err))
    end

    local retryCount = 0
    local maxRetryCount = self.config.websocketsMaxRetryCount
    local framesPool = {}

    -- event loop
    while true do
        --[[
        Receives a WebSocket frame from the wire.

        In case of an error, returns two nil values and a string describing the error.

        The second return value is always the frame type, which could be
        one of continuation, text, binary, close, ping, pong, or nil (for unknown types).

        For close frames, returns 3 values: the extra status message
        (which could be an empty string), the string "close", and a Lua number for
        the status code (if any). For possible closing status codes, see

        http://tools.ietf.org/html/rfc6455#section-7.4.1

        For other types of frames, just returns the payload and the type.

        For fragmented frames, the err return value is the Lua string "again".
        ]]
        local frame, ftype, err = socket:recv_frame()
        if err then
            if err == "again" then
                framesPool[#framesPool + 1] = frame
            elseif retryCount < maxRetryCount then
                printInfo("WebSocketServerBase:runEventLoop() - failed to receive frame, %s", err)
                retryCount = retryCount + 1
            else
                break -- exit event loop
            end
            goto recv_next_message
        end

        if #framesPool > 0 then
            -- merging fragmented frames
            framesPool[#framesPool + 1] = frame
            frame = table.concat(framesPool)
            framesPool = {}
        end

        if ftype == "close" then
            break -- exit event loop
        elseif ftype == "ping" then
            local bytes, err = socket:send_pong()
            if err then
                printInfo("WebSocketServerBase:runEventLoop() - failed to send pong, %s", err)
            end
        elseif ftype == "pong" then
            -- client ponged
        elseif ftype == "text" or ftype == "binary" then
            local ok, err = self:_processMessage(frame, ftype)
            if err then
                printWarn("WebSocketServerBase:runEventLoop() - process %s message failed, %s", ftype, err)
            end
        else
            printWarn("WebSocketServerBase:runEventLoop() - unknwon frame type \"%s\"", tostring(ftype))
        end

::recv_next_message::

    end -- while

    -- end the subscribe thread
    self:_unsubscribeBroadcastChannel()

    -- unbinding websocket id
    self:unsetSidTag(self._tag)

    -- close connect
    self._socket:send_close()
    self._socket = nil

    self:dispatchEvent({name = WebSocketServerBase.WEBSOCKET_CLOSE_EVENT})

    return exitError
end

function WebSocketServerBase:_processMessage(rawMessage, messageType)
    local message, err = self:_parseMessage(rawMessage, messageType)
    if err then
        return nil, err
    end

    local msgid = message.__id
    local actionName = message.action
    local err = nil
    local ok, result = xpcall(function()
        return self:doRequest(actionName, message)
    end, function(_err)
        err = tostring(_err) .. "\n" .. debug.traceback("", 2)
    end)
    if err then
        return nil, string.format("action \"%s\" occurs error, %s", actionName, err)
    end

    if type(result) ~= "table" then
        if msgid then
            return nil, string.format("action \"%s\" return invalid result for message [__id:\"%s\"]", actionName, msgid)
        else
            return nil, string.format("action \"%s\" return invalid result", actionName)
        end
    end

    if not msgid then
        printWarn("WebSocketServerBase:processMessage() - action \"%s\" return unused result", actionName)
        return true
    end

    if not self._socket then
        return nil, "socket removed"
    end

    result.__id = msgid
    local rawMessage, err = self:_packMessage(result, messageType)
    if err then
        return nil, err
    end

    local bytes, err = self._socket:send_text(rawMessage)
    if err then
        return nil, err
    end

    return true
end

function WebSocketServerBase:_packMessage(message, messageType)
    -- TODO: support message type plugin
    if messageType ~= WebSocketServerBase.TEXT_MESSAGE_TYPE then
        return nil, string.format("not supported message type \"%s\"", messageType)
    end
    return json.encode(message)
end

function WebSocketServerBase:_parseMessage(rawMessage, messageType)
    -- TODO: support message type plugin
    if messageType ~= WebSocketServerBase.TEXT_MESSAGE_TYPE then
        return nil, string.format("not supported message type \"%s\"", messageType)
    end

    -- TODO: support message format plugin
    if self.config.websocketsMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return message
        else
            return nil, "not supported message format"
        end
    else
        return nil, string.format("not support message format \"%s\"", tostring(self.config.websocketsMessageFormat))
    end
end

function WebSocketServerBase:_unsubscribeBroadcastChannel()
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    -- once this WebSocketServerApp receives "QUIT" from channel.quit, message loop will be ended.
    local ok, err = redis:command("publish", self.internalChannel, "QUIT")
    if not ok then
        printWarn("WebSocketServerBase:unsubscribeBroadcastChannel() - publish QUIT failed: %s", err)
    end
    redis:close()
end

function WebSocketServerBase:_subscribeBroadcastChannel()
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
            printError("WebSocketServerBase, subscribe thread - redis subscribe channel failed: %s", err)
            ngx_exit(ngx.HTTP_SERVICE_UNAVAILABLE)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                printInfo("WebSocketServerBase, subscribe thread - subscribed channel(%s), socket id: %d", msg.channel, self.socketId)
            elseif msg.kind == "message" then
                local payload = msg.payload
                printInfo("WebSocketServerBase, subscribe thread - get msg from channel(%s), socket id: %d, msg: %s", msg.channel, self.socketId, payload)
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

        printInfo("WebSocketServerBase, subscribe thread - quit from subscribe loop, socketId = %d", self.socketId)
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

function WebSocketServerBase:_authConnect()
    if ngx.headers_sent then
        error("WebSocketServerBase:authConnect() - response header already sent")
    end

    req_read_body()
    local headers = ngx.req.get_headers()
    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) == "table" then
        protocols = protocols[1]
    else
        protocols = nil
    end
    if not protocols then
        error("WebSocketServerBase:authConnect() - not set header: Sec-WebSocket-Protocol")
    end

    local token = string.match(protocols, WebSocketServerBase.PROTOCOL_PATTERN)
    if not token then
        error("WebSocketServerBase:authConnect() - not set token in header")
    end

    -- TODO: check token
    return true
end

return WebSocketServerBase
