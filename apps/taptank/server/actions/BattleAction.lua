
local BattleAction = class("BattleAction")

local Tank = import("..models.Tank")

function BattleAction:ctor(connect)
    printInfo("new BattleAction instance")
    self.connect = connect
    self.battle = connect.battle
end

function BattleAction:enterAction(arg)
    local uid = self.connect:getSession():get("uid")
    local tank = Tank:create(uid)
    local message = tank:enter()
    if message then
        self.connect.tank = tank
        self.battle:addTankEvent(uid, "enter", message)
        self.battle:boardcastEvent(uid, "enter", message)
    end
end

function BattleAction:moveAction(arg)
    local tank = self.connect.tank
    local message = tank:move(arg.x, arg.y, arg.rotation, arg.destx, arg.desty)
    if message then
        local uid = tank:getUid()
        self.battle:addTankEvent(uid, "move", message)
        self.battle:boardcastEvent(uid, "move", message)
    end
end

return BattleAction
