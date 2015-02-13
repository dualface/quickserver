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
local _MONITOR_LIST_LEN_KEY = "_MONITOR_LIST_LENGTH"
local _MONITOR_CPU_LIST_PATTERN = "_MONITOR_%s_CPU_%s_LIST"
local _MONITOR_MEM_LIST_PATTERN = "_MONITOR_%s_MEM_%s_LIST"

-- since this tool is running background as a loop,
-- redis connection don't need closing.
local RedisService = cc.load("redis").service

local MaintainAction = class("Maintain")

function MaintainAction:ctor(app)
    self._app = app
    self._process = self.config.monitor.process
    self._interval = self.config.monitor.interval 
    self._secListLen = 0
    self._minuteListLen = 0
    self._hourListLen = 0
    self._procData = {}
    self._isProcessRestart = false
end

function MaintainAction:monitorAction(arg)
    local sock = require("socket")
    local elapseSec = 0
    local elapseMin = 0
    local interval = self._interval

    while true do
        _getPid()
        _getPerfomance()
        _save(elapseSec/60, elapseMin/60)
        sock.select(nil, nil, interval) 
        if elapseSec >= 60 then
            elapseSec = elapseSec % 60
        end
        if elapseMin >= 60 then
            elapseMin = elapseMin % 60
        end

        elapseSec = elapseSec + interval
        elapseMin = elapseMin + (elapseSec / 60)
    end
end

function MaintainAction:_save(isUpdateMinList, isUpdateHourList)
    local secListLen = self._secListLen
    local maxSecLen = 600 / self._interval
    local minuteListLen = self._minuteListLen
    local hourListLen = self._hourListLen

    local pipe = self:getRedis():newPipeline()
    for k, v in pairs(self._procData) do
        local cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, k, "SEC")
        local memList = string_format(_MONITOR_MEM_LIST_PATTERN, k, "SEC")
        local cpuRatio = v[1]
        local memRatio = v[2]
        pipe:command("RPUSH", cpuList, cpuRatio)
        pipe:command("RPUSH", memList, memRatio)
        if secListLen == maxSecLen then 
            pipe:command("LPOP", cpuList)
            pipe:command("LPOP", memList)
        end

        if isUpdateMinList then
            cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, k, "MINUTE")
            memList = string_format(_MONITOR_MEM_LIST_PATTERN, k, "MINUTE")
            pipe:command("RPUSH", cpuList, cpuRatio)
            pipe:command("RPUSH", memList, memRatio)
            if minuteListLen == 60 then
                pipe:command("LPOP", cpuList)
                pipe:command("LPOP", memList)
            end
        end
        
        if isUpdateHourList then
            cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, k, "HOUR")
            memList = string_format(_MONITOR_MEM_LIST_PATTERN, k, "HOUR")
            pipe:command("RPUSH", cpuList, cpuRatio)
            pipe:comand("RPUSH", memList, memRatio)
            if hourListLen == 24 then
                pipe:command("LPOP", cpuList)
                pipe:command("LPOP", memList)
            end
        end
    end
    pipe:commit()

    if secListLen < maxSecLen then
        self._secListLen = self._secListLen + 1
    end
    if isUpdateMinList and minuteListLen < 60 then
        self._minuteListLen = self._minuteListLen + 1
    end
    if isUpdateHourList and hourListLen < 24 then
        self._hourListLen = self._hourListLen + 1
    end
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

    local process = self._process
    local pipe = self.getRedis():newPipeline()
    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()

        local pids = string_split(res, "\n")
        for i, pid in ipairs(pids) do
            local pName
            if procName == "nginx" then
                if i == 1 then    
                    pName = procName .. " master" 
                else 
                    pName = procName .. " worker#" .. tostring(i)
                end
            else 
                pName = procName
            end

            self._procData[pid] = {}
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pid, pName)
        end
    end
    pipe:commit()

    self._isProcessRestart = false
end

function MaintainAction:getRedis()
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
