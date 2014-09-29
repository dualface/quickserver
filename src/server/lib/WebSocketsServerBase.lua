
local ServerAppBase = import(".ServerAppBase")

local WebSocketsServerBase = class("WebSocketsServerBase", ServerAppBase)

WebSocketsServerBase.WEBSOCKETS_READY_EVENT = "WEBSOCKETS_READY_EVENT"
WebSocketsServerBase.WEBSOCKETS_CLOSE_EVENT = "WEBSOCKETS_CLOSE_EVENT"

function WebSocketsServerBase:ctor(config)
    WebSocketsServerBase.super.ctor(self, config)

    self.requestType = "websockets"
    self.config.websocketsTimeout = self.config.websocketsTimeout or 10 * 1000
    self.config.websocketsMaxPayloadLen = self.config.websocketsMaxPayloadLen or 16 * 1024
    self.config.websocketsMessageFormat = self.config.websocketsMessageFormat or "json"

    local ok, err = ngx.on_abort(function()
        self:dispatchEvent({name = ServerAppBase.CLIENT_ABORT_EVENT})
    end)
    if not ok then
        echoInfo("failed to register the on_abort callback, ", err)
    end

    if self.config.session then
        self.session = cc.server.Session.new(self)
    end

    self.websocketInfo= {}
end

function WebSocketsServerBase:closeClientConnect()
    if self.websockets then
        self.websockets:send_close()
        self.websockets = nil
    end
end

function WebSocketsServerBase:runEventLoop()
    local server = require("resty.websocket.server")
    local wb, err = server:new({
        timeout = self.config.websocketsTimeout,
        max_payload_len = self.config.websocketsMaxPayloadLen,
        --timeout = 5000,
        --max_payload_len = 65535,
    })

    if not wb then
        echoInfo("failed to new websocket: ".. err)
        return ngx.HTTP_SERVICE_UNAVAILABLE
    end

    self.websockets = wb
    self:dispatchEvent({name = WebSocketsServerBase.WEBSOCKETS_READY_EVENT})

    local ret = ngx.OK
    -- event loop
    while true do
        local data, typ, err = wb:recv_frame()
        if wb.fatal then
            echoInfo("failed to receive frame, %s", err)
            if err == "again" then
                goto recv_next_message
            end
            ret = 444
            break
        end

        if not data then
            -- timeout, send ping
            local bytes, err = wb:send_ping()
            if not bytes and self.config.debug then
                echoInfo("failed to send ping, %s", err)
            end
        elseif typ == "close" then
            break -- exit event loop
        elseif typ == "ping" then
            -- send pong
            local bytes, err = wb:send_pong()
            if not bytes and self.config.debug then
                echoInfo("failed to send pong, %s", err)
            end
        elseif typ == "pong" then
            -- ngx.log(ngx.ERR, "client ponged")
        elseif typ == "text" then
            local ok, err = self:processWebSocketsMessage(data, typ)
            if not ok then
                echoInfo("process text message failed: %s", err)
            end
        elseif typ == "binary" then
            local ok, err = self:processWebSocketsMessage(data, typ)
            if not ok then
                echoInfo("process binary message failed: %s", err)
            end
        else
            echoInfo("unknwon typ %s", tostring(typ))
        end

::recv_next_message::

    end -- while

    self:dispatchEvent({name = WebSocketsServerBase.WEBSOCKETS_CLOSE_EVENT})
    wb:send_close()
    self.websockets = nil

    -- release mysql & redis connections
    self:relRedis()
    self:relMysql()

    -- dec online numbers in the channel
    if self.websocketInfo.channel ~= nil then
        local chs = ngx.shared.CHANNELS
        chs:incr(self.websocketInfo.channel, -1)
        echoInfo("number in channel = %s", tostring(chs:get(self.websocketInfo.channel)))
    end

    return ret
end

function WebSocketsServerBase:processWebSocketsMessage(rawMessage, messageType)
    if messageType ~= "text" then
        return false, string.format("not supported message type %s", messageType)
    end

    local ok, message = self:parseWebSocketsMessage(rawMessage)
    if not ok then
        return false, message
    end

    local msgid = message._msgid
    local actionName = message.action
    local userDefModule = message.user_def_mod

    echoInfo("msgid: %s, action: %s, user_def_mod: %s", message._msgid, message.action, message.user_def_mod)

    local result = self:doRequest(actionName, message, userDefModule)
    if type(result) == "table" then
        if msgid then
            result._msgid = msgid
        else
            if self.config.debug then
                echoInfo("unused result from action %s", actionName)
            end
            result = nil
        end
    elseif result ~= nil then
        if msgid then
            echoInfo("invalid result from action %s for message %s", actionName, msgid)
            result = {error = result}
        else
            echoInfo("invalid result from action %s", actionName)
            result = nil
        end
    end

    if not self.websockets then
        return false, "websockets removed"
    end

    if result then
        local bytes, err = self.websockets:send_text(json.encode(result))
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
            return false, string.format("invalid message format %s", tostring(rawMessage))
        end
    else
        return false, string.format("not support message format %s", tostring(self.config.websocketsMessageFormat))
    end
end

return WebSocketsServerBase
