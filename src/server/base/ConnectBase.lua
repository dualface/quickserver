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

local clone = clone
local checktable = checktable
local ngx = ngx
local ngx_now = ngx.now
local ngx_md5 = ngx.md5
local json_encode = json.encode

local Constants = import(".Constants")
local SessionService = import(".SessionService")
local RedisService = cc.load("redis").service

local ActionDispatcher = import(".ActionDispatcher")
local ConnectBase = class("ConnectBase", ActionDispatcher)

function ConnectBase:ctor(config)
    ConnectBase.super.ctor(self, config)
    self.config.messageFormat = self.config.messageFormat or Constants.DEFAULT_MESSAGE_FORMAT
end

function ConnectBase:run()
    throw("ConnectBase:run() - must override in inherited class")
end

function ConnectBase:runEventLoop()
    throw("ConnectBase:runEventLoop() - must override in inherited class")
end

function ConnectBase:getSession()
    return self._session
end

function ConnectBase:openSession(sid)
    if self._session then
        throw("session \"%s\" already exists, disallow open an other session", self._session:getSid())
    end
    if type(sid) ~= "string" or sid == "" then
        throw("open session with invalid sid")
    end
    self._session = self:_loadSession(sid)
    return self._session
end

function ConnectBase:newSession()
    if self._session then
        throw("session \"%s\" already exists, disallow start a new session", self._session:getSid())
    end
    self._session = self:_genSession()
    return self._session
end

function ConnectBase:destroySession(sid)
    local session = self._session
    if not session then
        session = self:_loadSession(sid)
    end
    if session then session:destroy() end
    self._session = nil
end

function ConnectBase:getConnectIdByTag(tag)
    if not tag then
        throw("get connect id by invalid tag \"%s\"", tostring(tag))
    else
        local redis = self:_getRedis()
        return redis:command("HGET", Constants.CONNECTS_TAG_DICT_KEY, tostring(tag))
    end
end

function ConnectBase:getConnectTagById(connectId)
    if not connectId then
        throw("get connect tag by invalid id \"%s\"", tostring(connectId))
    else
        local redis = self:_getRedis()
        return redis:command("HGET", Constants.CONNECTS_ID_DICT_KEY, tostring(connectId))
    end
end

function ConnectBase:closeConnectByTag(tag)
    local connectId = self:getConnectIdByTag(tag)
    if connectId then
        self:sendMessageToConnect(connectId, "QUIT")
    end
end

function ConnectBase:sendMessageToConnect(connectId, message)
    if not connectId or not message then
        throw("send message to connect with invalid id \"%s\" or invalid message", tostring(connectId))
    else
        local redis = self:_getRedis()
        local channel = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
        redis:command("PUBLISH", channel, tostring(message))
    end
end

function ConnectBase:_loadSession(sid)
    local redis = self:_getRedis()
    local session = SessionService.load(redis, sid, self.config.sessionExpiredTime, ngx.var.remote_addr)
    if session then
        session:setKeepAlive()
        printInfo("load session \"%s\"", sid)
    end
    return session
end

function ConnectBase:_genSession()
    local addr = ngx.var.remote_addr
    local now = ngx_now()
    math.newrandomseed()
    local random = math.random() * 100000000000000
    local mask = string.format("%0.5f|%0.10f|%s", now, random, self._secret)
    local origin = string.format("%s|%s", addr, ngx_md5(mask))
    local sid = ngx_md5(origin)
    return SessionService:create(self:_getRedis(), sid, self.config.sessionExpiredTime, addr)
end

function ConnectBase:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function ConnectBase:_newRedis()
    local redis = RedisService:create(self.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

function ConnectBase:_genOutput(result, err)
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

return ConnectBase
