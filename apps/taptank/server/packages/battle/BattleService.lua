
local ngx_now = ngx.now

local BattleService = class("BattleService")

local RedisService = cc.load("redis").service

local _BATTLE_CHANNEL = "_BATTLE"
local _ONLINE_REDIS_KEY = '_ONLINE'

function BattleService:ctor(connect, uid)
    self._connect = connect
    self._uid = uid

    self._redis = RedisService:create(connect.config.redis)
    self._redis:connect()

    self:addUser(uid)
    self:subscribeBattleChannel()
end

function BattleService:quit()
    self._redis:command("SREM", _ONLINE_REDIS_KEY, self._uid)
    self:boardcastEvent(self._uid, "remove", {})
end

function BattleService:addTankEvent(uid, event)
end

function BattleService:addUser(uid)
    self._redis:command("SADD", _ONLINE_REDIS_KEY, uid)
end

function BattleService:removeUser(uid)
    self._redis:command("SREM", _ONLINE_REDIS_KEY, uid)
end

function BattleService:getAllUsers()
    return self._redis:command("SMEMBERS", _ONLINE_REDIS_KEY)
end

function BattleService:getAllOtherUsers()
    local all = self:getAllUsers()
    for index, uid in ipairs(all) do
        if self._uid == uid then
            table.remove(all, index)
            break
        end
    end
    return all
end

function BattleService:boardcastEvent(sender, event, message)
    message.__uid   = sender
    message.__event = event
    message.__time  = ngx_now()

    local message = json.encode(message)
    if message == json.null or not message then
        throw("message can't encoding to json")
    end
    self._connect:sendMessageToChannel(_BATTLE_CHANNEL, message)
end

function BattleService:subscribeBattleChannel()
    self._connect:subscribeChannel(_BATTLE_CHANNEL, function(payload)
        -- forward message to connect
        self._connect:sendMessageToSelf(payload)
        return true
    end)
end

function BattleService:unsubscribeBattleChannel()
    self._connect:unsubscribeChannel(_BATTLE_CHANNEL)
end

return BattleService
