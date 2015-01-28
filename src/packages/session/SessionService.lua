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

local tostring = tostring
local type = type
local clone = clone
local checktable = checktable
local json_encode = json.encode
local json_decode = json.decode
local ngx_null = ngx.null

local SessionService = class("SessionService")

local _SID_KEY_PREFIX = "_SID_"

function SessionService.load(redis, sid, expired, remoteAddr)
    local key = _SID_KEY_PREFIX .. sid
    local data = redis:command("GET", key)
    if data == "" or data == nil or data == ngx_null then return end

    data = json_decode(data)
    if type(data) == "table" then
        if sid ~= data.__id or remoteAddr ~= data.__addr then
            throw("load session with invalid sid \"%s\"", sid)
        end
        data.__id = nil
        data.__addr = nil
        return SessionService:create(redis, sid, expired, remoteAddr, data)
    else
        printWarn("found invalid session by sid \"%s\"", sid)
        redis:command("DEL", key)
    end
end

function SessionService:ctor(redis, sid, expired, remoteAddr, data)
    self._redis = redis
    self._sid = sid
    self._expired = expired
    self._remoteAddr = remoteAddr
    self._data = clone(checktable(data))
end

function SessionService:getSid()
    return self._sid
end

function SessionService:getExpired()
    return self._expired
end

function SessionService:get(key)
    if type(key) ~= "string" then
        error("invalid session read key \"%s\" type", tostring(key))
    end
    return self._data[key]
end

function SessionService:set(key, value)
    if type(key) ~= "string" then
        error("invalid session save key \"%s\" type", tostring(key))
    end
    local vtype = type(value)
    if vtype ~= "number" and vtype ~= "boolean" and vtype ~= "string" then
        error("invalid session value type for key \"%s\"", key)
    end
    self._data[tostring(key)] = value
end

function SessionService:save()
    local key = _SID_KEY_PREFIX .. self._sid
    self._redis:command("SET", key, json_encode(self:vardump()))
    self._redis:command("EXPIRE", key, self._expired)
end

function SessionService:destroy()
    local key = _SID_KEY_PREFIX .. self._sid
    self._redis:command("DEL", key)
end

function SessionService:vardump()
    local v = clone(self._data)
    v.__id = self._sid
    v.__addr = self._remoteAddr
    return v
end

return SessionService
