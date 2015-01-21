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

local sidKey = "sid_key_"

local ServerAppBase = class("ServerAppBase")

ServerAppBase.APP_RUN_EVENT          = "APP_RUN_EVENT"
ServerAppBase.APP_QUIT_EVENT         = "APP_QUIT_EVENT"
ServerAppBase.CLIENT_ABORT_EVENT     = "CLIENT_ABORT_EVENT"

function ServerAppBase:ctor(config)
    cc.bind(self, "event")

    self.isRunning = true
    self.config = clone(totable(config))
    self.config.appModuleName = config.appModuleName or "app"
    self.config.actionPackage = config.actionPackage or "actions"
    self.config.actionModuleSuffix = config.actionModuleSuffix or "Action"

    self.actionModules_ = {}
end

function ServerAppBase:run()
    self:dispatchEvent({name = ServerAppBase.APP_RUN_EVENT})
    local ret = self:runEventLoop()
    self.isRunning = false
    self:dispatchEvent({name = ServerAppBase.APP_QUIT_EVENT, ret = ret})
end

function ServerAppBase:runEventLoop()
    throw(ERR_SERVER_OPERATION_FAILED, "ServerAppBase:runEventLoop() - must override in inherited class")
end

function ServerAppBase:doRequest(actionName, data)
    local actionPackage = self.config.actionPackage

    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionMethodName = actionMethodName .. "Action"
    local actionModulePath = string.format("%s.%s%s", actionPackage, actionModuleName, self.config.actionModuleSuffix)

    local actionModule = self.actionModules_[actionModuleName] or self:require(actionModulePath)
    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        throw(ERR_SERVER_INVALID_ACTION, "failed to load action module %s", actionModuleName)
    end

    local action = actionModule.new(self)
    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw(ERR_SERVER_INVALID_ACTION, "invalid action %s:%s", actionModuleName, actionMethodName)
    end

    if not data then
        data = self.requestParameters or {}
    end

    return method(action, data)
end

function ServerAppBase:registerActionModule(actionModuleName, actionModule)
    if type(actionModuleName) ~= "string" then
        throw(ERR_SERVER_INVALID_ACTION, "invalid action module name")
    end
    actionModuleName = string.ucfirst(string.lower(actionModuleName))
    self.actionModules_[actionModuleName] = actionModule
end

function ServerAppBase:require(moduleName)
    moduleName = self.config.appModuleName .. "." .. moduleName

    return require(moduleName)
end

function ServerAppBase:normalizeActionName(actionName)
    local actionName = actionName or (self.GET.action or "index.index")
    actionName = string.gsub(actionName, "[^%a.]", "")
    actionName = string.gsub(actionName, "^[.]+", "")
    actionName = string.gsub(actionName, "[.]+$", "")

    local parts = string.split(actionName, ".")
    if #parts == 1 then parts[2] = 'index' end
    method = string.lower(parts[#parts])
    table.remove(parts, #parts)
    parts[#parts] = string.ucfirst(string.lower(parts[#parts]))

    return table.concat(parts, "."), method
end

function ServerAppBase:newSessionId(data)
    if not data.tag then
        return nil, "miss parameter tag."
    end

    local app = self.config.appName
    local time = os.time()
    local ip = ngx.var.remote_addr

    local str = app .. "!" .. time .. "!" .. data.tag .. "!" .. ip
    local sessionId = ngx.md5(str)

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    redis:command("SET", sessionId, str)
    redis:command("EXPIRE", sessionId, self.config.sessionExpiredTime) 
    redis:close()

    return sessionId, nil
end

function ServerAppBase:sendMessage(sid, msg)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ch = string.format("channel.%s", sid) 
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
    if sid == ngx.null then
        redis:close()    
        return nil, "sid does NOT exist"
    end
    redis:close()

    return sid, nil
end

function ServerAppBase:setSidTag(key)
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local ok, err = redis:command("INCR", sidKey)
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, "Generate websocketUid failed: %s", err)
    end
    self.socketId = ok
    self.internalChannel = string.format("channel.%s", self.socketId)
    redis:command("SET", key, ok)

    redis:close()
end

function ServerAppBase:checkSessionId(data)
    local sessionId = data.session_id
    if not sessionId then
        return nil, "check session id failed: session id is null" 
    end

    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()
    local str, err = redis:command("GET", sessionId)
    if not str then
        redis:close()
        return nil, string.format("check session id failed: %s", err)
    end

    if str == ngx.null then
        redis:close()
        return nil, "check session id failed: session id is expired"
    end

    local oriStrTable = string.split(str, "!")
    local ip = ngx.var.remote_addr
    if data.app_name ~= oriStrTable[1] or data.tag ~= oriStrTable[3] or ip ~= oriStrTable[4] then 
        redis:close()
        return nil, "check session id failed: verify failed"
    end

    redis:command("EXPIRE", sessionId, self.config.sessionExpiredTime) 
    redis:close()

    return data.tag, nil
end

return ServerAppBase
