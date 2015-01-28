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

    local ok, err = ngx.on_abort(function()
        self:dispatchEvent({name = ServerAppBase.CLIENT_ABORT_EVENT})
    end)
    if not ok then
        printWarn("WebSocketServerBase:ctor() - failed to register the on_abort callback, %s", err)
    end
end

function WebSocketServerBase:authConnect()
    if ngx.headers_sent then
        return nil, "response header already sent"
    end

    read_body()
    local headers = ngx.req.get_headers()

    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) == "table" then
        protocols = protocols[1]
    else
        protocols = nil
    end
    if not protocols then
        return nil, "not set header: Sec-WebSocket-Protocol"
    end

    local token = string.match(protocols, WebSocketServerBase.PROTOCOL_PATTERN)
    if not token then
        return nil, "not set token in header"
    end


end

function WebSocketServerBase:run()
    local ok, err = self:authConnect()
    if not ok then
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

    if not socket then
        error(string.format("WebSocketServerBase:runEventLoop() - failed to create websocket server, %s", err))
    end

    -- use createAndCheckSession() authentication client
    local ok, err = self:createAndCheckSession()
    if not ok then
        error(string.format("WebSocketServerBase:runEventLoop() - check session [1] failed, %s", err))
    end

    self._socket = socket
    self:dispatchEvent({name = WebSocketServerBase.WEBSOCKET_READY_EVENT})

    local exitError = nil
    local retryCount = 0
    local maxRetryCount = self.config.websocketsMaxRetryCount
    local framesPool = {}

    -- event loop
    while true do
        local frame, ftype, err = wb:recv_frame()
        if not frame then
            if err and retryCount < maxRetryCount then
                retryCount = retryCount + 1
                goto recv_next_message
            end
            exitError = ServerAppBase.WEBSOCKET_RECV_FRAME_ERROR
            break
        end

        if err == "again" then
            -- append current frame to pool
            framesPool[#framesPool + 1] = frame
            goto recv_next_message
        end

        if next(framesPool) ~= nil then
            frame = table.concat(framesPool)
            framesPool = {}
        end

        if ftype == "close" then
            break -- exit event loop
        elseif ftype == "ping" then
            -- send pong
            local bytes, err = wb:send_pong()
            if not bytes and DEBUG > 1 then
                printInfo("WebSocketServerBase:runEventLoop() - failed to send pong, %s", err)
            end
        elseif ftype == "pong" then
            -- client ponged
        elseif ftype == "text" or ftype == "binary" then
            -- use checkSession() authentication client
            local ok, err = self:checkSession()
            if not ok then
                error(string.format("WebSocketServerBase:runEventLoop() - check session [2] failed, %s", err))
            end

            local ok, err = self:processMessage(frame, ftype)
            if not ok then
                printWarn("WebSocketServerBase:runEventLoop() - process %s message failed, %s", ftype, err)
            end
        else
            printWarn("WebSocketServerBase:runEventLoop() - unknwon frame type \"%s\"", tostring(ftype))
        end

::recv_next_message::

    end -- while

    self._socket:send_close()
    self._socket = nil

    self:dispatchEvent({name = WebSocketServerBase.WEBSOCKET_CLOSE_EVENT})
end

function WebSocketServerBase:processMessage(rawMessage, messageType)
    local ok, message = self:parseMessage(rawMessage, messageType)
    if not ok then
        -- message is error
        return nil, message
    end

    local msgid = message.__id
    local actionName = message.action
    local ok, result = pcall(function() return self:doRequest(actionName, message) end)

    if not ok then
        return nil, string.format("action \"%s\" occus error, %s", actionName, result)
    end

    if type(result) ~= "table" then
        if msgid then
            return nil, string.format("action \"%s\" return invalid result for message [__id:\"%s\"]", actionName, msgid)
        else
            return nil, string.format("action \"%s\" return invalid result", actionName)
        end
    end

    if not msgid then
        return nil, string.format("action \"%s\" return unused result", actionName)
    end

    if not self._socket then
        return nil, "socket removed"
    end

    result.__id = msgid
    local ok, message = self:packMessage(result)
    if not ok then
        return nil, message
    end

    local bytes, err = self._socket:send_text(message)
    if not bytes then
        return nil, err
    end

    return true
end

function WebSocketServerBase:packMessage(message, messageType)
    -- TODO: support message type plugin
    if messageType ~= WebSocketServerBase.TEXT_MESSAGE_TYPE then
        return nil, string.format("not supported message type \"%s\"", messageType)
    end
    return true, json.encode(message)
end

function WebSocketServerBase:parseMessage(rawMessage, messageType)
    -- TODO: support message type plugin
    if messageType ~= WebSocketServerBase.TEXT_MESSAGE_TYPE then
        return nil, string.format("not supported message type \"%s\"", messageType)
    end

    -- TODO: support message format plugin
    if self.config.websocketsMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return true, message
        else
            return nil, "not supported message format"
        end
    else
        return nil, string.format("not support message format \"%s\"", tostring(self.config.websocketsMessageFormat))
    end
end

function WebSocketServerBase:processWebSocketSession()
    local wb = self._socket
    if not wb then
        return nil, "verify session id failed: websocket is unavailabel."
    end

    wb:send_text("verifysession")
    local data, typ, err = wb:recv_frame()
    if not data then
        return nil, string.format("verify session id failed: %s", err)
    end

    if typ ~= "text" then
        return nil, "verify session id failed: receive a non-text frame."
    end

    data, err = json.decode(data)
    if not data then
        return nil, string.format("verify session id failed: %s", err)
    end

    return self:checkSessionId(data)
end

return WebSocketServerBase
