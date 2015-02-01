
local WebSocketHandler = class("")

function WebSocketHandler:ctor(server)
    -- server is WebSocketServerApp instance
    self._server = server
end

function WebSocketHandler:convertTokenToSessionId(token)
    -- WebSocketServerApp fetch token from HTTP header "Sec-WebSocket-Protocol"
    -- convertTokenToSessionId() convert it to session id
    return token
end

function WebSocketHandler:onConnectReady()
    -- websocket connection ready
    local session = self._server:getSession()
    local tag = session:get("tag")
    if not tag then
        throw("invalid tag")
    end
    self._server:setConnectTag(tag)
end

function WebSocketHandler:onConnectClose()
    -- websocket connection closed
end

return WebSocketHandler
