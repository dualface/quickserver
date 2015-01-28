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

ServerAppBase.APP_RUN_EVENT      = "APP_RUN_EVENT"
ServerAppBase.APP_QUIT_EVENT     = "APP_QUIT_EVENT"
ServerAppBase.CLIENT_ABORT_EVENT = "CLIENT_ABORT_EVENT"

local _CLIENT_ID_PREFIX      = "C_"
local _CLIENT_TAG_PREFIX     = "T_"
local _CLIENT_TAG_PREFIX_LEN = string_len(_CLIENT_TAG_PREFIX)
local _TAG_CLIENT_ID_DICT    = "_CLIENT_TAGS"

local RedisService = cc.load("redis").service
local SessionService = cc.load("session").service

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
    end
    if not session then
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

function ServerAppBase:getClientId()
    if not self._clientId then
        self._clientId = _CLIENT_ID_PREFIX .. ngx_md5(tostring(ngx.ctx))
    end
    return self._clientId
end

function ServerAppBase:setClientTag(tag)
    local clientId = self:getClientId()
    tag = tostring(tag)
    tagkey = _CLIENT_TAG_PREFIX .. tag
    local redis = self:_getInternalRedis()
    redis:command("HMSET", _TAG_CLIENT_ID_DICT, clientId, tagkey, tagkey, clientId)
    self._clientTag = tag
end

function ServerAppBase:getClientTag()
    if not self._clientTag then
        local clientId = self:getClientId()
        local redis = self:_getInternalRedis()
        local tagkey = redis:command("HGET", _TAG_CLIENT_ID_DICT, clientId)
        if type(tagkey) == "string" then
            self._clientTag = string_sub(tagkey, _CLIENT_TAG_PREFIX_LEN + 1)
        end
    end
    return self._clientTag
end

function ServerAppBase:getClientIdByTag(tag)
    tagkey = _CLIENT_TAG_PREFIX .. tostring(tag)
    local redis = self:_getInternalRedis()
    redis:command("HGET", _TAG_CLIENT_ID_DICT, tagkey)
end

function ServerAppBase:getClientTagById(clientId)
    local redis = self:_getInternalRedis()
    local tagkey = redis:command("HGET", _TAG_CLIENT_ID_DICT, clientId)
    if type(tagkey) == "string" then
        return string_sub(tagkey, _CLIENT_TAG_PREFIX_LEN + 1)
    end
end

function ServerAppBase:unsetClientTag()
    if not self._clientId then return end
    local clientId = self:getClientId()
    local tagkey = _CLIENT_TAG_PREFIX .. tostring(self:getClientTag())
    local redis = self:_getInternalRedis()
    redis:command("HDEL", _TAG_CLIENT_ID_DICT, clientId, tagkey)
end

function ServerAppBase:sendMessageToClient(clientId, message)
    local redis = self:_getInternalRedis()
    local channel = string.format("channel.%s", clientId)
    redis:command("PUBLISH", channel, message)
end

function ServerAppBase:_loadSession(sid)
    local redis = self:_getInternalRedis()
    return SessionService.load(redis, sid, self.config.sessionExpiredTime, ngx.var.remote_addr)
end

function ServerAppBase:_genSession()
    local addr = ngx.var.remote_addr
    local now = ngx_now()
    math.newrandomseed()
    local random = math.random() * 100000000000000
    local mask = string.format("%0.5f|%0.10f|%s", now, random, self._secret)
    local origin = string.format("%s|%s", addr, ngx_md5(mask))
    local sid = ngx_md5(origin)
    return SessionService:create(self:_getInternalRedis(), sid, self.config.sessionExpiredTime, addr)
end

function ServerAppBase:_getInternalRedis()
    if not self._internalRedis then
        self._internalRedis = RedisService:create(self.config.redis)
    end

    local ok, err = self._internalRedis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end

    return self._internalRedis
end

return ServerAppBase
