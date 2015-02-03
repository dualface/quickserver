
local ngx_now = ngx.now

local BattleAction = class("BattleAction")

local Tank = import("..models.Tank")
local Game = import("..models.Game")

function BattleAction:ctor(app)
    printInfo("new BattleAction instance")
    self._app = app
    self._firstMove = true
end

function BattleAction:_boardcastEvent(event, message)
    local app = self._app
    message.__sid = app:getSession():getSid()
    message.__event = event
    message.__time = ngx_now()

    local message = json.encode(message)
    if message == json.null or not message then
        throw("message can't encoding to json")
    end
    self._app:sendMessageToBattleChannel(message)
end

function BattleAction:enterAction(arg)
    self._app:subscribeBattleChannel()
    local tank = Tank:create()
    self._app.tank = tank
    tank:setRandomPosition()
    local result = {x = tank.x, y = tank.y, rotation = tank.rotation}
    self:_boardcastEvent("enter", result)
    return result
end

function BattleAction:moveAction(arg)
    local tank = self._app.tank
    local result = tank:move(arg.cx, arg.cy, arg.cr, arg.x, arg.y)
    if result then
        self:_boardcastEvent("move", result)
    end

    if not self._firstMove then
        self._app:unsubscribeBattleChannel()
    end
    self._firstMove = false
end

return BattleAction
