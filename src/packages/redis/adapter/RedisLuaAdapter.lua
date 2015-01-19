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

local redis = require("3rd.redis.redis_lua")

local RedisLuaAdapter = class("RedisLuaAdapter")

function RedisLuaAdapter:ctor(config)
    self.config = config
    self.name = "RedisLuaAdapter"
end

function RedisLuaAdapter:connect()
    local ok, result = pcall(function()
        self.instance = redis.connect({
            host = self.config.host,
            port = self.config.port,
            timeout = self.config.timeout
        })
    end)
    if ok then
        return true
    else
        return false, result
    end
end

function RedisLuaAdapter:close()
    return self.instance:quit()
end

function RedisLuaAdapter:command(command, ...)
    local method = self.instance[command]
    assert(type(method) == "function", string.format("RedisLuaAdapter:command() - invalid command %s", tostring(command)))

    if self.config.debug then
        local a = {}
        table.walk({...}, function(v) a[#a + 1] = tostring(v) end)
        printf("[REDIS] %s: %s", string.upper(command), table.concat(a, ", "))
    end

    local arg = {...}
    local ok, result = pcall(function()
        return method(self.instance, unpack(arg))
    end)
    if ok then
        return result
    else
        return false, result
    end
end

function RedisLuaAdapter:pubsub(subscriptions)
    return pcall(function()
        return self.instance:pubsub(subscriptions)
    end)
end

function RedisLuaAdapter:commitPipeline(commands)
    return pcall(function()
        self.instance:pipeline(function()
            if self.config.debug then print("[REDIS] INIT PIPELINE") end
            for _, arg in ipairs(commands) do
                local command = arg[1]
                local method = self.instance[command]
                assert(type(method) == "function", string.format("RedisLuaAdapter:commitPipeline() - invalid command %s", tostring(command)))
                method(self.instance, unpack(arg[2]))
            end
            if self.config.debug then print("[REDIS] COMMIT PIPELINE") end
        end)
    end)
end

return RedisLuaAdapter
