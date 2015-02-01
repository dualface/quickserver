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

local clone = clone
local checktable = checktable
local pcall = pcall
local ngx = ngx
local ngx_exit = ngx.exit
local ngx_now = ngx.now
local ngx_md5 = ngx.md5
local table_remove = table.remove
local table_concat = table.concat
local string_sub = string.sub
local string_len = string.len
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_ucfirst = string.ucfirst
local json_encode = json.encode
local json_decode = json.decode
local os_time = os.time

local ServerAppBase = class("ServerAppBase")

local Constants = import(".Constants")
local RedisService = cc.load("redis").service
local SessionService = cc.load("session").service

function ServerAppBase:ctor(config)
    cc.bind(self, "event")

    self.config = clone(checktable(config))

    self.config.appRootPath = self.config.appRootPath or ""
    if self.config.appRootPath ~= "" then
        package.path = self.config.appRootPath .. "/?.lua;" .. package.path
    end

    self.config.actionModuleSuffix = config.actionModuleSuffix or Constants.DEFAULT_ACTION_MODULE_SUFFIX
    self.config.messageFormat      = self.config.messageFormat or Constants.DEFAULT_MESSAGE_FORMAT

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
        actionModulePath = string_format("%s.%s%s", Constants.ACTION_PACKAGE_NAME, actionModuleName, self.config.actionModuleSuffix)
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
    local actionName = actionName
    if not actionName or actionName == "" then
        actionName = "index.index"
    end
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

function ServerAppBase:startSession(sid)
    local session
    if sid then
        session = self:_loadSession(sid)
    else
        session = self:_genSession()
    end
    self._session = session
    return session
end

function ServerAppBase:destroySession(sid)
    local session = self._session
    if not session then
        session = self:_loadSession(sid)
    end
    if session then session:destroy() end
    self._session = nil
end

function ServerAppBase:getConnectIdByTag(tag)
    if not tag then
        throw("get connect id by invalid tag \"%s\"", tostring(tag))
    else
        local redis = self:_getRedis()
        return redis:command("HGET", Constants.CONNECTS_TAG_DICT_KEY, tostring(tag))
    end
end

function ServerAppBase:getConnectTagById(connectId)
    if not connectId then
        throw("get connect tag by invalid id \"%s\"", tostring(connectId))
    else
        local redis = self:_getRedis()
        return redis:command("HGET", Constants.CONNECTS_ID_DICT_KEY, tostring(connectId))
    end
end

function ServerAppBase:sendMessageToConnect(connectId, message)
    if not connectId or not message then
        throw("send message to connect with invalid id \"%s\" or invalid message", tostring(connectId))
    else
        local redis = self:_getRedis()
        local channel = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
        redis:command("PUBLISH", channel, tostring(message))
    end
end

function ServerAppBase:_loadSession(sid)
    local redis = self:_getRedis()
    local session = SessionService.load(redis, sid, self.config.sessionExpiredTime, ngx.var.remote_addr)
    if session then session:setKeepAlive() end
    return session
end

function ServerAppBase:_genSession()
    local addr = ngx.var.remote_addr
    local now = ngx_now()
    math.newrandomseed()
    local random = math.random() * 100000000000000
    local mask = string.format("%0.5f|%0.10f|%s", now, random, self._secret)
    local origin = string.format("%s|%s", addr, ngx_md5(mask))
    local sid = ngx_md5(origin)
    return SessionService:create(self:_getRedis(), sid, self.config.sessionExpiredTime, addr)
end

function ServerAppBase:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function ServerAppBase:_newRedis()
    local redis = RedisService:create(self.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

function ServerAppBase:_genOutput(result, err)
    local rtype = type(result)
    if self.config.messageFormat == Constants.MESSAGE_FORMAT_JSON then
        if err then
            result = {err = err}
        elseif rtype == "nil" then
            result = {}
        elseif rtype ~= "table" then
            result = {result = tostring(result)}
        end
        return json_encode(result)
    elseif self.config.messageFormat == Constants.MESSAGE_FORMAT_TEXT then
        if err then
            return nil, err
        elseif rtype == "nil" then
            return ""
        else
            return tostring(result)
        end
    end
end

return ServerAppBase
