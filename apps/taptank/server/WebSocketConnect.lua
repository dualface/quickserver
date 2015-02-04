
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

local BattleService = cc.load("battle").service

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
end

function WebSocketConnect:afterConnectReady()
    -- init
    local uid = self:getSession():get("uid")
    self:setConnectTag(uid)
    self.battle = BattleService:create(self, uid)
end

function WebSocketConnect:beforeConnectClose()
    -- cleanup
    self.battle:quit()
end

return WebSocketConnect
