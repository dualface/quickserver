
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local Game = import(".models.Game")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase, Game)

local OnlineService = cc.load("online").service

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
    self.online = OnlineService:create(config.redis)
end

function WebSocketConnect:getOnlineUsers()
    return self.online:getAll()
end

function WebSocketConnect:getAllOtherUsers()
    local cur = self:getConnectTag()
    local all = self.online:getAll()
    for index, tag in ipairs(all) do
        if cur == tag then
            table.remove(all, index)
            break
        end
    end
    return all
end

function WebSocketConnect:afterConnectReady()
    -- websocket connection ready
    local session = self:getSession()
    local tag = session:get("tag")
    if not tag then
        throw("invalid tag")
    end
    self:setConnectTag(tag)

    -- save tag into online users list
    self.online:add(tag)
end

function WebSocketConnect:beforeConnectClose()
    -- remove tag from online users list
    self.online:remove(self:getConnectTag())
end

return WebSocketConnect
