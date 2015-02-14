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
local string_sub = string.sub
local string_upper = string.upper
local string_split = string.split
local io_popen = io.popen

local _GET_PID_PATTERN = "pgrep %s"
local _GET_PERFORMANCE_PATTERN = "ps -p %s -o pcpu= -o rss="

local _RESET_REDIS_CMD = [[/opt/qs/bin/redis/bin/redis-server /opt/qs/bin/redis/conf/redis.conf]]
local _RESET_NGINX_CMD = [[nginx -p /opt/qs -c /opt/qs/bin/openresty/nginx/conf/nginx.conf]]
local _RESET_BEANSTALKD_CMD = [[/opt/qs/bin/beanstalkd/bin/beanstalkd > /opt/qs/logs/beanstalkd.log &]]

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_CPU_LIST_PATTERN = "_MONITOR_%s_CPU_%s_LIST"
local _MONITOR_MEM_LIST_PATTERN = "_MONITOR_%s_MEM_%s_LIST"

-- since this tool is running background as a loop,
-- redis connection don't need closing.
local RedisService = cc.load("redis").service

local MaintainAction = class("Maintain")

function MaintainAction:ctor(cmd)
    self._cmd = cmd
    self._process = cmd.config.monitor.process
    self._interval = cmd.config.monitor.interval
    self._procData = {}
    self._memThreshold = cmd.config.mem
    self._cpuThreshold = cmd.config.cpu
end

function MaintainAction:monitorAction(arg)
    local sock = require("socket")
    local elapseSec = 0
    local elapseMin = 0
    local interval = self._interval

    while true do
        self:_getPid()
        self:_getPerfomance()
        self:_save(elapseSec/60, elapseMin/60)
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
    local maxSecLen = 600 / self._interval

    local pipe = self:getRedis():newPipeline()
    for k, v in pairs(self._procData) do
        local secListLen = v.secListLen
        local minuteListLen = v.minuteListLen
        local hourListLen = v.hourListLen
        printf("3 len: %d %d %d", secListLen, minuteListLen, hourListLen)
        local cpuRatio = v.cpu
        local memRatio = v.mem

        local cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, k, "SEC")
        local memList = string_format(_MONITOR_MEM_LIST_PATTERN, k, "SEC")
        pipe:command("RPUSH", cpuList, cpuRatio)
        pipe:command("RPUSH", memList, memRatio)
        if secListLen == maxSecLen then
            pipe:command("LPOP", cpuList)
            pipe:command("LPOP", memList)
        end

        if isUpdateMinList ~= 0 then
            cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, k, "MINUTE")
            memList = string_format(_MONITOR_MEM_LIST_PATTERN, k, "MINUTE")
            pipe:command("RPUSH", cpuList, cpuRatio)
            pipe:command("RPUSH", memList, memRatio)
            if minuteListLen == 60 then
                pipe:command("LPOP", cpuList)
                pipe:command("LPOP", memList)
            end
        end

        if isUpdateHourList ~= 0 then
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
end

function MaintainAction:_getPerfomance()
    for k, _ in pairs(self._procData) do
        local pid = self._procData[k].pid
        local cmd = string_format(_GET_PERFORMANCE_PATTERN, pid)
        local fout = io_popen(cmd)
        local res = string_sub(fout:read("*a"), 1, -2) -- trim "\n"
        local tRes = string_split(res, " ")
        self._procData[k].cpu = tRes[1]
        self._procData[k].mem = tRes[2]

        -- get current list len
        local redis = self:getRedis()
        self._procData[k].secListLen = redis:command("LLEN", string_format(_MONITOR_CPU_LIST_PATTERN, k, "SEC"))
        self._procData[k].minuteListLen = redis:command("LLEN", string_format(_MONITOR_CPU_LIST_PATTERN, k, "MINUTE"))
        self._procData[k].hourListLen = redis:command("LLEN", string_format(_MONITOR_CPU_LIST_PATTERN, k, "HOUR"))
    end

    for k, v in pairs(self._procData) do
        printf("%s pid %s: cpu %s, mem %s", k, v.pid, v.cpu, v.mem)
    end
end

function MaintainAction:_getPid()
    local process = self._process
    local pipe = self:getRedis():newPipeline()
    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()

        while res == "" do
            res = self:_resetProcess(procName)
        end

        local pids = string_split(res, "\n")
        printf("pids = %s", res)
        for i, pid in ipairs(pids) do
            local pName = string_upper(procName)
            if procName == "nginx" then
                if i == 1 then
                    pName = pName .. "_MASTER"
                else
                    pName = pName .. "_WORKER_#" .. tostring(i-1)
                end
            else
                pName = pName .. "_#" .. tostring(i)
            end

            if type(self._procData[pName]) == "table"  then
                local oldPid = self._procData[pName].pid
                pip:command("HDEL", _MONITOR_PROC_DICT_KEY, oldPid)
            end
            self._procData[pName] = {}
            self._procData[pName].pid = pid
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pName, pid)
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pid, pName)
        end
    end
    pipe:commit()
end

function MaintainAction:_resetProcess(procName)
    if procName == "nginx" then
        os_execute(_RESET_NGINX_CMD)
    end

    if procName == "redis-server" then
        os_execute(_RESET_REDIS_CMD)
    end

    if procName == "beanstalkd" then
        os_execute(_RESET_BEANSTALKD_CMD)
    end

    local cmd = string_format("pgrep %s", procName)
    local fout = io_popen(cmd)
    local res = fout:read("*a")
    fout:close()

    return res
end

function MaintainAction:getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function MaintainAction:_newRedis()
    local redis = RedisService:create(self._cmd.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return MaintainAction
