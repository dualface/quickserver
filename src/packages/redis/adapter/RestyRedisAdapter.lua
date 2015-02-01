--[[

Copyright (c) 2011-2015 chukong-inc.com

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

local assert = assert
local type = type
local ipairs = ipairs
local tostring = tostring
local ngx_null = ngx.null
local table_concat = table.concat
local table_remove = table.remove
local table_walk = table.walk
local string_lower = string.lower
local string_upper = string.upper
local string_format = string.format
local string_match = string.match

local redis = require("resty.redis")

local RestyRedisAdapter = class("RestyRedisAdapter")

function RestyRedisAdapter:ctor(config)
    self._config = config
    self._instance = redis:new()
    self.name = "RestyRedisAdapter"
end

function RestyRedisAdapter:connect()
    self._instance:set_timeout(self._config.timeout)
    return self._instance:connect(self._config.host, self._config.port)
end

function RestyRedisAdapter:close()
    return self._instance:close()
end

function RestyRedisAdapter:setKeepAlive(timeout, size)
    if size then
        return self._instance:set_keepalive(timeout, size)
    elseif timeout then
        return self._instance:set_keepalive(timeout)
    else
        return self._instance:set_keepalive()
    end
end

local function _formatCommand(args)
    local result = {}
    table_walk(args, function(v) result[#result + 1] = tostring(v) end)
    return table_concat(result, ", ")
end

function RestyRedisAdapter:command(command, ...)
    command = string_lower(command)
    local method = self._instance[command]
    if type(method) ~= "function" then
        local err = string_format("invalid redis command \"%s\"", string_upper(command))
        printError("%s", err)
        return nil, err
    end

    if DEBUG > 1 then
        printInfo("redis command: %s %s", string_upper(command), _formatCommand({...}))
    end

    local res, err = method(self._instance, ...)
    if res == ngx_null then res = nil end
    return res, err
end

function RestyRedisAdapter:pubsub(subscriptions)
    if type(subscriptions) ~= "table" then
        return nil, "invalid redis subscriptions argument"
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
            local result, err = f(self._instance, channel)
            if result then
                subscribeMessages[#subscribeMessages + 1] = result
            end
        end
    end

    local function unsubscribe(f, channels)
        for _, channel in ipairs(channels) do
            f(self._instance, channel)
        end
    end

    local aborting, subscriptionsCount = false, 0
    local function abort()
        if aborting then return end
        if subscriptions.subscribe then
            unsubscribe(self._instance.unsubscribe, subscriptions.subscribe)
        end
        if subscriptions.psubscribe then
            unsubscribe(self._instance.punsubscribe, subscriptions.psubscribe)
        end
        aborting = true
    end

    if subscriptions.subscribe then
        subscribe(self._instance.subscribe, subscriptions.subscribe)
    end
    if subscriptions.psubscribe then
        subscribe(self._instance.psubscribe, subscriptions.psubscribe)
    end

    return coroutine.wrap(function()
        while true do
            local result, err
            if #subscribeMessages > 0 then
                result = subscribeMessages[1]
                table_remove(subscribeMessages, 1)
            else
                result, err = self._instance:read_reply()
            end

            if not result then
                if err ~= "timeout" then
                    printWarn("RestyRedisAdapter, subscribe thread - redis read reply message failed: %s" , err)
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

                if string_match(message.kind, '^p?subscribe$') then
                    subscriptionsCount = subscriptionsCount + 1
                end
                if string_match(message.kind, '^p?unsubscribe$') then
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

function RestyRedisAdapter:commitPipeline(commands)
    self._instance:init_pipeline()
    for _, arg in ipairs(commands) do
        self:command(arg[1], unpack(arg[2]))
    end
    return self._instance:commit_pipeline()
end

return RestyRedisAdapter
