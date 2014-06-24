
local redis = import(".redis_lua")

local RedisLuaAdapter = class("RedisLuaAdapter")

function RedisLuaAdapter:ctor(easy)
    self.config = easy.config
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
