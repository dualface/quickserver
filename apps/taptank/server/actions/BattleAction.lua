
local ngx_now = ngx.now
local json_encode = json.encode

local BattleAction = class("BattleAction")

local Tank = import("..models.Tank")

function BattleAction:ctor(connect)
    printInfo("new BattleAction instance")
    self.connect = connect
    self.battle = connect.battle
end

function BattleAction:enterAction(arg)
    local connect = self.connect
    local battle = connect.battle

    local uid = connect:getSession():get("uid")
    local tank = Tank:create(uid)
    local message = tank:enter()
    if not message then return end

    connect.tank = tank
    battle:boardcastEvent(uid, "enter", message)

    local messages = battle:getCurrentTankMessages()
    messages[uid] = nil
    local current = ngx_now()
    for _, message in pairs(messages) do
        local uid = message.__uid
        local event = message.__event
        local time = message.__time
        if event == "enter" then
            -- forward to current connect
        elseif event == "move" then
            message = Tank.simulateMove(message, current)
        else
            -- skip unknown message
            message = nil
        end
        if message then
            connect:sendMessageToSelf(json_encode(message))
        end
    end
end

function BattleAction:moveAction(arg)
    local tank = self.connect.tank
    local message = tank:move(arg.x, arg.y, arg.rotation, arg.destx, arg.desty)
    if not message then return end

    local uid = tank:getUid()
    self.battle:boardcastEvent(uid, "move", message)
end

return BattleAction
