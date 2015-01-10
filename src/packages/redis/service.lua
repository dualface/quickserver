local RedisService = class("RedisService")

function RedisService:ctor(config) 
    local red = require("resty.redis")
    self.config = config or {host = "127.0.0.1", port = 6379, timeout = 10*1000}
    self.redis = red:new()
end

function RedisService:connect()
    local redis = self.redis
    local config = self.config
    if not redis then 
        return nil, "Package redis is not initialized."    
    end

    redis:set_timeout(config.timeout)
    return redis:connect(config.host, config.port)
end

function RedisService:close() 
    local redis = self.redis
    local config = self.config
    if not redis then 
        return nil, "Package redis is not initialized."    
    end

    if config.useConnPool then 
        return redis:set_keepalive(10000, 100) 
    end 

    return redis:close()
end

function RedisService:command(command, ...)
    local method = self.redis[command]
    if type(method) ~= "function" then 
        return nil, string.format("invalid command %s", tostring(command))
    end

    return method(self.redis, ...)
end

function RedisService:pubsub(subscriptions)
    if type(subscriptions) ~= "table" then
        return nil, "invalid subscriptions argument"
    end

    if type(subscriptions.subscribe) == "string" then
        subscriptions.subscribe = {subscriptions.subscribe}
    end
    if type(subscriptions.psubscribe) == "string" then
        subscriptions.psubscribe = {subscriptions.psubscribe}
    end

    local subscribeMessages = {}

    local function subscribe(f, channels)
        for _, channel in ipairs(channels) do
            local result, err = f(self.redis, channel)
            if result then
                subscribeMessages[#subscribeMessages + 1] = result
            end
        end
    end

    local function unsubscribe(f, channels)
        for _, channel in ipairs(channels) do
            f(self.redis, channel)
        end
    end

    local aborting, subscriptionsCount = false, 0
    local function abort()
        if aborting then return end
        if subscriptions.subscribe then
            unsubscribe(self.redis.unsubscribe, subscriptions.subscribe)
        end
        if subscriptions.psubscribe then
            unsubscribe(self.redis.punsubscribe, subscriptions.psubscribe)
        end
        aborting = true
    end

    if subscriptions.subscribe then
        subscribe(self.redis.subscribe, subscriptions.subscribe)
    end
    if subscriptions.psubscribe then
        subscribe(self.redis.psubscribe, subscriptions.psubscribe)
    end

    return coroutine.wrap(function()
        while true do
            local result, err
            if #subscribeMessages > 0 then
                result = subscribeMessages[1]
                table.remove(subscribeMessages, 1)
            else
                result, err = self.redis:read_reply()
            end

            if not result then
                if err ~= "timeout" then
                    echoInfo(err)
                    abort()
                    break
                end
            else
                local message
                if result[1] == "pmessage" then
                    message = {
                        kind = result[1],
                        pattern = result[2],
                        channel = result[3],
                        payload = result[4],
                    }
                else
                    message = {
                        kind = result[1],
                        channel = result[2],
                        payload = result[3],
                    }
                end

                if string.match(message.kind, '^p?subscribe$') then
                    subscriptionsCount = subscriptionsCount + 1
                end
                if string.match(message.kind, '^p?unsubscribe$') then
                    subscriptionsCount = subscriptionsCount - 1
                end

                if aborting and subscriptionsCount == 0 then
                    break
                end
                coroutine.yield(message, abort)
            end
        end
    end)
end

function RedisService:commitPipeline(commands)
    self.redis:init_pipeline()
    for _, arg in ipairs(commands) do
        self:command(arg[1], unpack(arg[2]))
    end
    return self.redis:commit_pipeline()
end

return RedisService
