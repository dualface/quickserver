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

local pcall = pcall
local type = type
local ngx = ngx
local ngx_exit = ngx.exit
local table_remove = table.remove
local table_concat = table.concat
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local os_time = os.time

local ServerAppBase = class("ServerAppBase")

ServerAppBase.APP_RUN_EVENT            = "APP_RUN_EVENT"
ServerAppBase.APP_QUIT_EVENT           = "APP_QUIT_EVENT"
ServerAppBase.CLIENT_ABORT_EVENT       = "CLIENT_ABORT_EVENT"

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
    self:dispatchEvent({name = ServerAppBase.APP_RUN_EVENT})
    self:runEventLoop()
    self:dispatchEvent({name = ServerAppBase.APP_QUIT_EVENT})
end

function ServerAppBase:runEventLoop()
    printError("ServerAppBase:runEventLoop() - must override in inherited class")
end

function ServerAppBase:doRequest(actionName, data)
    local actionPackage = self.config.actionPackage

    -- parse actionName
    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionMethodName = actionMethodName .. self.config.actionModuleSuffix

    -- check registered action module before load module
    local actionModule = self._actionModules[actionModuleName]
    if not actionModule then
        local actionModulePath = string_format("%s.%s.%s%s", self.config.appModuleName, actionPackage, actionModuleName, self.config.actionModuleSuffix)
        local ok, _actionModule = pcall(require,  actionModulePath)
        if ok then actionModule = _actionModule end
    end

    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        printError("ServerAppBase:doRequest() - failed to load action module \"%s\"", actionModulePath)
        ngx_exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local action = actionModule.new(self)
    local method = action[actionMethodName]
    if type(method) ~= "function" then
        printError("ServerAppBase:doRequest() - invalid action method \"%s:%s()\"", actionModulePath, actionMethodName)
        ngx_exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if not data then
        -- self._requestParameters can be set by HttpServerBase
        data = self._requestParameters or {}
    end

    local result = method(action, data)
    local rtype = type(result)
    if rtype == "table" then
        return result
    end

    error(string.format("ServerAppBase:doRequest() - action method \"%s:%s()\" result is unexpected type \"%s\"", actionModulePath, actionMethodName, rtype))
end

function ServerAppBase:registerActionModule(actionModuleName, actionModule)
    if type(actionModuleName) ~= "string" then
        printError("ServerAppBase:registerActionModule() - invalid action module name \"%s\"", actionModuleName)
        ngx_exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    if type(actionModule) ~= "table" or type(actionModule) ~= "userdata" then
        printError("ServerAppBase:registerActionModule() - invalid action module \"%s\"", actionModuleName)
        ngx_exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    actionModuleName = string.ucfirst(string_lower(actionModuleName))
    self._actionModules[actionModuleName] = actionModule
end

function ServerAppBase:normalizeActionName(actionName)
    local actionName = actionName or "index.index"
    actionName = string_gsub(actionName, "[^%a.]", "")
    actionName = string_gsub(actionName, "^[.]+", "")
    actionName = string_gsub(actionName, "[.]+$", "")

    local parts = string.split(actionName, ".")
    if #parts == 1 then parts[2] = 'index' end
    method = string_lower(parts[#parts])
    table_remove(parts, #parts)
    parts[#parts] = string.ucfirst(string_lower(parts[#parts]))

    return table_concat(parts, "."), method
end

function ServerAppBase:newSession(data)
    if not data.tag then
        return nil, "miss parameter tag."
    end

    local app = self.config.appName
    local time = os_time()
    local ip = ngx.var.remote_addr

    local str = app .. "!" .. time .. "!" .. data.tag .. "!" .. ip
    local token = ngx.md5(str)

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    redis:command("SET", token, str)
    redis:command("EXPIRE", token, self.config.sessionExpiredTime)
    redis:close()

    return token, nil
end

function ServerAppBase:sendMessage(sid, msg)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ch = string_format("channel.%s", sid)
    redis:command("PUBLISH", ch, msg)

    redis:close()
end

function ServerAppBase:getSidByTag(key)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local sid = redis:command("GET", key)
    if sid == nil then
        redis:close()
        return nil, err
    end
    if ngx and sid == ngx.null then
        redis:close()
        return nil, "sid does NOT exist"
    end
    redis:close()

    return sid, nil
end

function ServerAppBase:setSidTag(key)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ok, err = redis:command("INCR", SID_KEY)
    if not ok then
        printError("ServerAppBase:setSidTag() - generate socket id failed: %s", err)
        ngx_exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
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
    if not str then
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

return ServerAppBase
