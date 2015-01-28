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

local ngx = ngx
local ngx_exit = ngx.exit
local table_remove = table.remove
local table_concat = table.concat
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_ucfirst = string.ucfirst
local os_time = os.time

local ServerAppBase = class("ServerAppBase")

ServerAppBase.APP_RUN_EVENT      = "APP_RUN_EVENT"
ServerAppBase.APP_QUIT_EVENT     = "APP_QUIT_EVENT"
ServerAppBase.CLIENT_ABORT_EVENT = "CLIENT_ABORT_EVENT"

local SID_KEY = "_SID_KEY"

function ServerAppBase:ctor(config)
    cc.bind(self, "event")

    self.config = clone(checktable(config))
    self.config.appModuleName = config.appModuleName or "app"
    self.config.actionPackage = config.actionPackage or "actions"
    self.config.actionModuleSuffix = config.actionModuleSuffix or "Action"

    self._actionModules = {}
    self._requestParameters = nil
end

function ServerAppBase:run()
    throw("ServerAppBase:run() - must override in inherited class")
end

function ServerAppBase:runEventLoop()
    throw("ServerAppBase:runEventLoop() - must override in inherited class")
end

function ServerAppBase:doRequest(actionName, data)
    local actionPackage = self.config.actionPackage

    -- parse actionName
    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionMethodName = actionMethodName .. self.config.actionModuleSuffix

    -- check registered action module before load module
    local actionModule = self._actionModules[actionModuleName]
    local actionModulePath
    if not actionModule then
        actionModulePath = string_format("%s.%s.%s%s", self.config.appModuleName, actionPackage, actionModuleName, self.config.actionModuleSuffix)
        local ok, _actionModule = pcall(require,  actionModulePath)
        if ok then
            actionModule = _actionModule
        end
    end

    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        throw("failed to load action module \"%s\"", actionModulePath or actionModuleName)
    end

    local action = actionModule.new(self)
    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw("invalid action method \"%s:%s()\"", actionModuleName, actionMethodName)
    end

    if not data then
        -- self._requestParameters can be set by HttpServerBase
        data = self._requestParameters or {}
    end

    return method(action, data)
end

function ServerAppBase:registerActionModule(actionModuleName, actionModule)
    if type(actionModuleName) ~= "string" then
        throw("invalid action module name \"%s\"", actionModuleName)
    end
    if type(actionModule) ~= "table" or type(actionModule) ~= "userdata" then
        throw("invalid action module \"%s\"", actionModuleName)
    end

    local action = actionModuleName .. ".index"
    local actionModuleName, _ = self:normalizeActionName(actionName)
    self._actionModules[actionModuleName] = actionModule
end

function ServerAppBase:normalizeActionName(actionName)
    local actionName = actionName or "index.index"
    actionName = string_lower(actionName)
    actionName = string_gsub(actionName, "[^%a.]", "")
    actionName = string_gsub(actionName, "^[.]+", "")
    actionName = string_gsub(actionName, "[.]+$", "")

    -- demo.hello.say --> {"demo", "hello", "say"]
    local parts = string.split(actionName, ".")
    local c = #parts
    if c == 1 then
        return string_ucfirst(parts[1]), "index"
    end
    -- method = "say"
    method = parts[c]
    table_remove(parts, c)
    c = c - 1
    -- mdoule = "demo.Hello"
    parts[c] = string_ucfirst(parts[c])
    return table_concat(parts, "."), method
end

function ServerAppBase:newSession(secret)
    local session = self:genSession(secret)
    -- TODO: add Redis, beanstalkd API into ServerAppBase
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    redis:command("SET", session.sid, session.origin)
    redis:command("EXPIRE", session.sid, self.config.sessionExpiredTime)
    redis:close()
    return session
end

function ServerAppBase:getSidByTag(tag)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local sid = redis:command("GET", tag)
    if sid == nil then
        redis:close()
        return nil, err
    end
    if ngx and sid == ngx.null then
        redis:close()
        return nil, "sid does NOT exist"
    end
    redis:close()

    return sid
end

function ServerAppBase:setSidTag(key)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ok, err = redis:command("INCR", SID_KEY)
    if err then
        throw("ServerAppBase:setSidTag() - generate socket id failed: %s", err)
    end
    self.socketId = ok
    self.internalChannel = string_format("channel.%s", self.socketId)
    redis:command("SET", key, ok)
    redis:close()
end

function ServerAppBase:unsetSidTag(key)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    redis:command("DEL", key)
    redis:close()
end

function ServerAppBase:checkSession(data)
    local token = data.token
    if not token then
        return nil, "check session failed: token is null"
    end

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local str, err = redis:command("GET", token)
    if err then
        redis:close()
        return nil, string_format("check session failed: %s", err)
    end

    if str == ngx.null then
        redis:close()
        return nil, "check session id failed: session is expired"
    end

    local oriStrTable = string.split(str, "!")
    local ip = ngx.var.remote_addr
    if data.app_name ~= oriStrTable[1] or data.tag ~= oriStrTable[3] or ip ~= oriStrTable[4] then
        redis:close()
        return nil, "check session failed: verify token failed"
    end

    redis:command("EXPIRE", token, self.config.sessionExpiredTime)
    redis:close()
    return data.tag, nil
end

function ServerAppBase:sendMessage(sid, msg)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ch = string.format("channel.%s", sid)
    redis:command("PUBLISH", ch, msg)
    redis:close()
end

function ServerAppBase:genSession(secret)
    if not secret then
        error("ServerAppBase:genSession() - miss \"secret\"")
    end

    local app = self.config.appName or "quickserver-app"
    local time = os.time()
    math.newrandomseed()
    local random = math.random()
    local ip = ngx.var.remote_addr
    local str = app .. "!" .. time .. "!" .. ngx.md5(random .. tostring(secret)) .. "!" .. ip
    local sid = ngx.md5(str)
    return {sid = sid, origin = str}
end

return ServerAppBase
