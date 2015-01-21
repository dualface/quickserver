--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local type = type
local pairs = pairs
local strLower = string.lower

local RedisService = class("RedisService")

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

local adapter
if ngx then
    adapter = import(".adapter.RestyRedisAdapter")
else
    adapter = import(".adapter.RedisLuaAdapter")
end
local trans = import(".RedisTransaction")
local pipline = import(".RedisPipeline")

function RedisService:ctor(config)
    if not config or type(config) ~= "table" then
        return nil, "config is invalid."
    end

    self.config = config or {host = "127.0.0.1", port = 6379, timeout = 10*1000}
    self.redis = adapter.new(self.config)
end

function RedisService:connect()
    local redis = self.redis
    if not redis then
        return nil, "Package redis is not initialized."
    end

    return redis:connect()
end

function RedisService:close()
    local redis = self.redis
    if not redis then
        return nil, "Package redis is not initialized."
    end

    return redis:close()
end

function RedisService:command(command, ...)
    local redis = self.redis
    if not redis then
        return nil, "Package redis is not initialized."
    end

    command = strLower(command)
    local res, err = redis:command(command, ...)
    if not err then
        -- converting result
        local convert = RESULT_CONVERTER[command]
        if convert and convert[redis.name] then
            res = convert[redis.name](self, res)
        end
    end

    return res, err
end

function RedisService:pubsub(subscriptions)
    local redis = self.redis
    if not redis then
        return nil, "Package redis is not initialized."
    end

    return self.redis:pubsub(subscriptions)
end

function RedisService:newPipeline()
    return pipline.new(self)
end

function RedisService:newTransaction(...)
    return trans.new(self, ...)
end

function RedisService:hashToArray(hash)
    local arr = {}
    for k, v in pairs(hash) do
        arr[#arr + 1] = k
        arr[#arr + 1] = v
    end

    return arr
end

function RedisService:arrayToHash(arr)
    local c = #arr
    local hash = {}
    for i = 1, c, 2 do
        hash[arr[i]] = arr[i + 1]
    end

    return hash
end

return RedisService
