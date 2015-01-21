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

local assert = assert
local type = type
local ipairs = ipairs
local tostring = tostring
local print = print
local tblConcat = table.concat
local tblRemove = table.remove
local tblWalk = table.walk
local strUpper = string.upper
local strFormat = string.format
local strMatch = string.match

local redis = require("resty.redis")

local RestyRedisAdapter = class("RestyRedisAdapter")

function RestyRedisAdapter:ctor(config)
    self.config = config
    self.instance = redis:new()
    self.name = "RestyRedisAdapter"
end

function RestyRedisAdapter:connect()
    self.instance:set_timeout(self.config.timeout)
    return self.instance:connect(self.config.host, self.config.port)
end

function RestyRedisAdapter:close()
    if self.config.useConnPool then
        return self.instance:set_keepalive(10000, 100)
    end
    return self.instance:close()
end

function RestyRedisAdapter:command(command, ...)
    local method = self.instance[command]
    assert(type(method) == "function", strFormat("RestyRedisAdapter:command() - invalid command %s", tostring(command)))

    if self.config.debug then
        local a = {}
        tblWalk({...}, function(v) a[#a + 1] = tostring(v) end)
        printf("[REDIS] %s: %s", strUpper(command), tblConcat(a, ", "))
    end

    return method(self.instance, ...)
end

function RestyRedisAdapter:pubsub(subscriptions)
    if type(subscriptions) ~= "table" then
        return false, "invalid subscriptions argument"
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
            local result, err = f(self.instance, channel)
            if result then
                subscribeMessages[#subscribeMessages + 1] = result
            end
        end
    end

    local function unsubscribe(f, channels)
        for _, channel in ipairs(channels) do
            f(self.instance, channel)
        end
    end

    local aborting, subscriptionsCount = false, 0
    local function abort()
        if aborting then return end
        if subscriptions.subscribe then
            unsubscribe(self.instance.unsubscribe, subscriptions.subscribe)
        end
        if subscriptions.psubscribe then
            unsubscribe(self.instance.punsubscribe, subscriptions.psubscribe)
        end
        aborting = true
    end

    if subscriptions.subscribe then
        subscribe(self.instance.subscribe, subscriptions.subscribe)
    end
    if subscriptions.psubscribe then
        subscribe(self.instance.psubscribe, subscriptions.psubscribe)
    end

    return coroutine.wrap(function()
        while true do
            local result, err
            if #subscribeMessages > 0 then
                result = subscribeMessages[1]
                tblRemove(subscribeMessages, 1)
            else
                result, err = self.instance:read_reply()
            end

            if not result then
                if err ~= "timeout" then
                    printInfo(err)
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

                if strMatch(message.kind, '^p?subscribe$') then
                    subscriptionsCount = subscriptionsCount + 1
                end
                if strMatch(message.kind, '^p?unsubscribe$') then
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
    self.instance:init_pipeline()
    if self.config.debug then print("[REDIS] INIT PIPELINE") end
    for _, arg in ipairs(commands) do
        self:command(arg[1], unpack(arg[2]))
    end
    if self.config.debug then print("[REDIS] COMMIT PIPELINE") end
    return self.instance:commit_pipeline()
end

return RestyRedisAdapter
