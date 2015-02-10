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

local string_format = string.format
local string_split = string.split
local io_popen = io.popen

local _GET_PID_PATTERN = "pgrep %s"
local _GET_PERFORMANCE_PATTERN = "ps -p %s -o pcpu= -o pmem=" 

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_CPU_LIST_PATTERN = "_MONITOR_%s_CPU"
local _MONITOR_MEM_LIST_PATTERN = "_MONITOR_%s_MEM"

-- since this tool is running background as a loop,
-- redis connection don't need closing.
local RedisService = cc.load("redis").service

local MaintainAction = class("Maintain") 

function MaintainAction:ctor(app)
    self._app = app 
    self.config.process = self.config.monitor.process

    self._procData = {}
    self._isProcessRestart = false
end

function MaintainAction:monitorAction(arg)
    _getPid()
    _getPerfomance() 
    _save()
end

function MaintainAction:_save()
    local pipe = self:_getRedis():newPipeline()
    for k, v in pairs(self._procData) do    
        local cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, "")
        local memList = string_format(_MONITOR_MEM_LIST_PATTERN, "")
        pipe:command("") 
    end
    pipe:commit()
end

function MaintainAction:_getPerfomance()
    for k, _ in pairs(self._procData) do
        local cmd = string_format(_GET_PERFORMANCE_PATTERN, k)
        local fout = io_popen(cmd)
        local res = string_sub(fout:read("*a"), 1, -2) -- trim "\n"
        self._procData[k] = string_split(res, " ")  
    end
end

function MaintainAction:_getPid()
    if not self._isProcessRestart then
        return 
    end

    local process = self.config.process
    local pipe = self._getRedis():newPipeline()

    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()

        local pids = string_split(res, "\n")
        for _, pid in ipairs(pids) do
            self._procData[pid] = {}
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pid, procName) 
        end
    end

    pipe:commit()

    self._isProcessRestart = false
end

function MaintainAction:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function MaintainAction:_newRedis()
    local redis = RedisService:create(self.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return MaintainAction
