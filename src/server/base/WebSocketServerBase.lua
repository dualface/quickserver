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
local ngx_thread_spawn = ngx.thread.spawn
local req_read_body = ngx.req.read_body
local req_get_headers = ngx.req.get_headers
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format

local ServerAppBase = import(".ServerAppBase")

local WebSocketServerBase = class("WebSocketServerBase", ServerAppBase)

local Constants = import(".Constants")
local Events = import(".Events")

function WebSocketServerBase:ctor(config)
    WebSocketServerBase.super.ctor(self, config)

    self.config.websocketsTimeout       = self.config.websocketsTimeout or Constants.WEBSOCKET_DEFAULT_TIME_OUT
    self.config.websocketsMaxPayloadLen = self.config.websocketsMaxPayloadLen or Constants.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN
    self.config.websocketsMaxRetryCount = self.config.websocketsMaxRetryCount or Constants.WEBSOCKET_DEFAULT_MAX_RETRY_COUNT
    self.config.maxSubscribeRetryCount  = self.config.maxSubscribeRetryCount or Constants.WEBSOCKET_DEFAULT_MAX_SUB_RETRY_COUNT

    self._requestType = "websockets"
    self._channelEnabled = false
    self._subscribeRetryCount = 0
end

function WebSocketServerBase:run()
    local connectId, err = self:_authConnect()
    if err then
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say(tostring(err))
        ngx.exit(ngx.ERROR)
    else
        self:dispatchEvent({name = Events.APP_RUN_EVENT})
        self:runEventLoop()
        self:dispatchEvent({name = Events.APP_QUIT_EVENT})
    end
end

function WebSocketServerBase:runEventLoop()
    local server = require("resty.websocket.server")
    local socket, err = server:new({
        timeout = self.config.websocketsTimeout,
        max_payload_len = self.config.websocketsMaxPayloadLen,
    })
    if err then
        throw("failed to create websocket server, %s", err)
    end

    -- spawn a thread to subscribe redis channel for broadcast
    self:_subscribeChannel()

    -- ready
    self._socket = socket
    self:dispatchEvent({name = Events.WEBSOCKET_READY_EVENT})

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
    self:_unsubscribeChannel()

    -- cleanup tag
    self:removeConnectTag()

    -- close connect
    self._socket:send_close()
    self._socket = nil

    self:dispatchEvent({name = Events.WEBSOCKET_CLOSE_EVENT})
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
        err = tostring(_err)
        if DEBUG > 1 then
            err = err .. "\n" .. debug.traceback("", 4)
        end
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
    if messageType ~= Constants.TEXT_MESSAGE_TYPE then
        return nil, string.format("not supported message type \"%s\"", messageType)
    end
    return json.encode(message)
end

function WebSocketServerBase:_parseMessage(rawMessage, messageType)
    -- TODO: support message type plugin
    if messageType ~= Constants.TEXT_MESSAGE_TYPE then
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

function WebSocketServerBase:_subscribeChannel()
    if self._channelEnabled then
        printWarn("already subscribed broadcast channel \"%s\"", self._channel)
        return
    end

    local function subscribe()
        self._channelEnabled = true
        local isRunning = true

        -- pubsub thread need separated redis connect
        local redis = self:_newRedis()

        local channel = self._channel
        local loop, err = redis:pubsub({subscribe = channel})
        if not loop then
            throw("subscribe channel \"%s\" failed, %s", channel, err)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                printInfo("subscribe channel \"%s\"", channel)
            elseif msg.kind == "message" then
                local payload = msg.payload
                printInfo("get msg from channel \"%s\", msg: %s", channel, payload)
                if payload == "QUIT" then
                    abort()
                    isRunning = false
                    break
                end
                -- forward message to connect
                self._socket:send_text(payload)
            end
        end

        -- when error occured or exit normally,
        -- connect will auto close, channel will be unsubscribed
        self._channelEnabled = false
        redis:setKeepAlive()
        printInfo("subscribe channel \"%s\" loop ended", channel)

        -- if an error leads to an exiting, retry to subscribe channel
        if isRunning and self._subscribeRetryCount < self.config.maxSubscribeRetryCount then
            self._subscribeRetryCount = self._subscribeRetryCount + 1
            self:_subscribeChannel()
        end
    end

    ngx_thread_spawn(subscribe)
end

function WebSocketServerBase:_unsubscribeChannel()
    local redis = self:_getRedis()
    redis:command("PUBLISH", self._channel, "QUIT")
end

function WebSocketServerBase:_authConnect()
    if ngx.headers_sent then
        return nil, "response header already sent"
    end

    req_read_body()
    local headers = ngx.req.get_headers()
    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) == "table" then
        protocols = protocols[1]
    end
    if not protocols then
        return nil, "not set header: Sec-WebSocket-Protocol"
    end

    local sid = string.match(protocols, Constants.WEBSOCKET_SUBPROTOCOL_PATTERN)
    if not sid then
        return nil, "not found session id in header: Sec-WebSocket-Protocol"
    end

    local session = self:startSession(sid)
    if not session then
        return nil, "not set valid session id in header: Sec-WebSocket-Protocol"
    end

    self._channel = Constants.CONNECT_CHANNEL_PREFIX .. self:getConnectId()
    return true
end

function WebSocketServerBase:getConnectId()
    if not self._connectId then
        local redis = self:_getRedis()
        self._connectId = tostring(redis:command("INCR", Constants.NEXT_CONNECT_ID_KEY))
    end
    return self._connectId
end

function WebSocketServerBase:setConnectTag(tag)
    if not tag then
        throw("set connect tag with invalid tag \"%s\"", tostring(tag))
    else
        local connectId = self:getConnectId()
        tag = tostring(tag)
        local pipe = self:_getRedis():newPipeline()
        pipe:command("HMSET", Constants.CONNECTS_ID_DICT_KEY, connectId, tag)
        pipe:command("HMSET", Constants.CONNECTS_TAG_DICT_KEY, tag, connectId)
        pipe:commit()
        self._connectTag = tag
    end
end

function WebSocketServerBase:getConnectTag()
    if not self._connectTag then
        local connectId = self:getConnectId()
        local redis = self:_getRedis()
        self._connectTag = redis:command("HGET", Constants.CONNECTS_ID_DICT_KEY, connectId)
    end
    return self._connectTag
end

function WebSocketServerBase:removeConnectTag()
    if not self._connectId then return end
    local connectId = self:getConnectId()
    local tag = self:getConnectTag()
    local pipe = self:_getRedis():newPipeline()
    pipe:command("HDEL", Constants.CONNECTS_ID_DICT_KEY, connectId)
    pipe:command("HMSET", Constants.CONNECTS_TAG_DICT_KEY, tag)
    pipe:commit()
end

return WebSocketServerBase
