
--[[--

local config = {
    host = "127.0.0.1",
    port = 6379,
    timeout = 10 * 1000, -- 10 seconds
}

local redis = RedisEasy.new(config)
local ok, err = redis:connect()
if err then
    -- ....
end

local result, err = redis:command(...)
lcoal result, err = redis:readReply()

local pipeline = redis:newPipeline()
pipeline:command(...)
pipeline:command(...)
local result, err = pipeline:commit()

local transition = redis:newTransition(watch1, watch2)
transition:watch(...)
transition:command(...)
transition:command(...)
local result, err = transition:commit()
-- transition:discard()

redis:close()

]]

local RedisEasy = class("RedisEasy")

local RedisAdapter
if ngx and ngx.log then
    RedisAdapter = import(".redis.RestyRedisAdapter")
else
    RedisAdapter = import(".redis.RedisLuaAdapter")
end

local RedisPipeline = import(".redis.RedisPipeline")
local RedisTransaction = import(".redis.RedisTransaction")

local RESULT_CONVERTER = {
    exists = {
        RedisLuaAdapter = function(self, r)
            if r == true then
                return 1
            else
                return 0
            end
        end,
    },

    hgetall = {
        RestyRedisAdapter = function(self, r)
            return self:arrayToHash(r)
        end,
    },

}

function RedisEasy:ctor(config)
    self.config = clone(totable(config))
    self.config.host = self.config.host or "127.0.0.1"
    self.config.port = self.config.port or 6379
    self.config.timeout = self.config.timeout or 10 * 1000
    self.config.debug = tobool(config.debug)
    self.adapter = RedisAdapter.new(self)
end

function RedisEasy:connect()
    return self.adapter:connect()
end

function RedisEasy:close()
    return self.adapter:close()
end

function RedisEasy:command(command, ...)
    command = string.lower(command)
    local res, err = self.adapter:command(command, ...)
    if not err then
        -- converting result
        local convert = RESULT_CONVERTER[command]
        if convert and convert[self.adapter.name] then
            res = convert[self.adapter.name](self, res)
        end
    end
    return res, err
end

function RedisEasy:pubsub(subscriptions)
    return self.adapter:pubsub(subscriptions)
end

function RedisEasy:newPipeline()
    return RedisPipeline.new(self)
end

function RedisEasy:newTransaction(...)
    return RedisTransaction.new(self, ...)
end

function RedisEasy:hashToArray(hash)
    local arr = {}
    for k, v in pairs(hash) do
        arr[#arr + 1] = k
        arr[#arr + 1] = v
    end
    return arr
end

function RedisEasy:arrayToHash(arr)
    local c = #arr
    assert(c % 2 == 0, "RedisEasy:arrayToHash() - invalid array")

    local hash = {}
    for i = 1, c, 2 do
        hash[arr[i]] = arr[i + 1]
    end
    return hash
end

return RedisEasy
