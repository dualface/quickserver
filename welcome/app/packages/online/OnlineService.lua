
local OnlineService = class("OnlineService")

local RedisService = cc.load("redis").service

local _ONLINE_REDIS_KEY = '_ONLINE'

function OnlineService:ctor(config)
    self._redis = RedisService:create(config)
    self._redis:connect()
end

function OnlineService:add(tag)
    self._redis:command("SADD", _ONLINE_REDIS_KEY, tag)
end

function OnlineService:remove(tag)
    self._redis:command("SREM", _ONLINE_REDIS_KEY, tag)
end

function OnlineService:getAll()
    return self._redis:command("SMEMBERS", _ONLINE_REDIS_KEY)
end

return OnlineService
