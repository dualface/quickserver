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
local string_find = string.find
local string_sub = string.sub
local string_upper = string.upper
local string_split = string.split
local io_popen = io.popen

local _RESET_REDIS_CMD = [[_QUICK_SERVER_ROOT_/bin/redis/bin/redis-server _QUICK_SERVER_ROOT_/bin/redis/conf/redis.conf]]
local _RESET_NGINX_CMD = [[nginx -p _QUICK_SERVER_ROOT_ -c _QUICK_SERVER_ROOT_/bin/openresty/nginx/conf/nginx.conf]]
local _RESET_BEANSTALKD_CMD = [[_QUICK_SERVER_ROOT_/bin/beanstalkd/bin/beanstalkd > _QUICK_SERVER_ROOT_/logs/beanstalkd.log &]]

local _GET_MEM_INFO_CMD = [[cat /proc/meminfo | grep -E "Mem(Free|Total)"]]
local _GET_DISK_INFO_CMD = [[df --total -k | grep "total"]]
local _GET_CPU_INFO_CMD = [[cat /proc/cpuinfo | grep "cpu cores"]]

local _GET_PID_PATTERN = "pgrep %s"
local _GET_PERFORMANCE_PATTERN = "ps -p %s -o pcpu= -o rss="

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_LIST_PATTERN = "_MONITOR_%s_%s_LIST"
local _MONITOR_MEM_INFO_KEY = "_MONITOR_MEM_INFO"
local _MONITOR_CPU_INFO_KEY = "_MONITOR_CPU_INFO"
local _MONITOR_DISK_INFO_KEY = "_MONITOR_DISK_INFO"

-- since this tool is running background as a loop,
-- redis connection don't need closing.
local RedisService = cc.load("redis").service

local BeansService = cc.load("beanstalkd").service

local http = require("3rd.http")

local WatchdogAction = class("Watchdog")

function WatchdogAction:ctor(cmd)
    self._cmd = cmd
    self._process = cmd.config.monitor.process
    self._interval = cmd.config.monitor.interval
    self._procData = {}
    self._memThreshold = cmd.config.mem
    self._cpuThreshold = cmd.config.cpu
end

function WatchdogAction:monitorAction(arg)
    local sock = require("socket")
    local elapseSec = 0
    local elapseMin = 0
    local interval = self._interval

    self:_getCpuInfo()
    self:_getMemInfo()
    self:_getDiskInfo()

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

function WatchdogAction:_getCpuInfo()
    local fout = io_popen(_GET_CPU_INFO_CMD)
    local res = string_match(fout:read("*a"), "cpu cores.*: (%d+)")
    fout:close()

    local redis = self:_getRedis()
    redis:command("SET", _MONITOR_CPU_CORES_KEY, res)

    return res
end

function MonitorAction:_getMemInfo()
    local fout = io_popen(_GET_MEM_INFO_CMD)
    local total, free = string_match(fout:read("*a"), "MemTotal:%s+(%d+).*MemFree:%s+(%d+)")
    fout:close()

    local redis = self:_getRedis()
    redis:command("SET", _MONITOR_MEM_INFO_KEY, total .. "|" .. free)
end

function MonitorAction:_getDiskInfo()
    local fout = io_popen(_GET_DISK_INFO_CMD)
    local total, free = string_match(fout:read("*a"), "total%s+(%d+) %d+ (%d+).*")
    fout:close()

    local redis = self:_getRedis()
    redis:command("SET", _MONITOR_DISK_INFO_KEY, total .. "|" .. free)
end

function WatchdogAction:_save(isUpdateMinList, isUpdateHourList)
    local maxSecLen = 600 / self._interval

    local pipe = self:_getRedis():newPipeline()
    for k, v in pairs(self._procData) do
        local secListLen = v.secListLen
        local minuteListLen = v.minuteListLen
        local hourListLen = v.hourListLen
        local data = v.cpu .. "|" .. v.mem .. "|" .. v.conn

        local list = string_format(_MONITOR_LIST_PATTERN, k, "SEC")
        pipe:command("RPUSH", list, data)
        if secListLen == maxSecLen then
            pipe:command("LPOP", list)
        end

        if isUpdateMinList ~= 0 then
            list = string_format(_MONITOR_LIST_PATTERN, k, "MINUTE")
            pipe:command("RPUSH", list, data)
            if minuteListLen == 60 then
                pipe:command("LPOP", list)
            end
        end

        if isUpdateHourList ~= 0 then
            list = string_format(_MONITOR_LIST_PATTERN, k, "HOUR")
            pipe:command("RPUSH", list, data)
            if hourListLen == 24 then
                pipe:command("LPOP", list)
            end
        end
    end
    pipe:commit()
end

function WatchdogAction:_getPerfomance()
    for k, _ in pairs(self._procData) do
        local pid = self._procData[k].pid
        local cmd = string_format(_GET_PERFORMANCE_PATTERN, pid)
        local fout = io_popen(cmd)
        local res = string_sub(fout:read("*a"), 1, -2) -- trim "\n"
        local tRes = string_split(res, " ")
        self._procData[k].cpu = tRes[1]
        self._procData[k].mem = tRes[2]
        self._procData[k].conn = self:_getConnNums(k)

        -- get current list len
        local redis = self:_getRedis()
        self._procData[k].secListLen = redis:command("LLEN", string_format(_MONITOR_LIST_PATTERN, k, "SEC"))
        self._procData[k].minuteListLen = redis:command("LLEN", string_format(_MONITOR_LIST_PATTERN, k, "MINUTE"))
        self._procData[k].hourListLen = redis:command("LLEN", string_format(_MONITOR_LIST_PATTERN, k, "HOUR"))
    end

    if DEBUG > 1 then
        for k, v in pairs(self._procData) do
            printInfo("%s pid %s: cpu %s, mem %s", k, v.pid, v.cpu, v.mem)
        end
    end
end

function WatchdogAction:_getPid()
    local process = self._process
    local pipe = self:_getRedis():newPipeline()
    for _, procName in ipairs(process) do
        local cmd = string_format(_GET_PID_PATTERN, procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()

        while res == "" do
            res = self:_resetProcess(procName)
        end

        local pids = string_split(res, "\n")
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

            self._procData[pName] = {}
            self._procData[pName].pid = pid
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pName, pid)
        end
    end
    pipe:commit()
end

function WatchdogAction:_resetProcess(procName)
    if procName == "nginx" then
        os_execute(_RESET_NGINX_CMD)
    end

    if procName == "redis-server" then
        os_execute(_RESET_REDIS_CMD)
    end

    if procName == "beanstalkd" then
        os_execute(_RESET_BEANSTALKD_CMD)
    end

    local cmd = string_format(_GET_PID_PATTERN, procName)
    local fout = io_popen(cmd)
    local res = fout:read("*a")
    fout:close()

    return res
end

function WatchdogAction:_getConnNums(procName)
    -- redis connections.
    if string_find(procName, "REDIS%-SERVER") then
        local redis = self:_getRedis()
        res = redis:command("INFO")
        return res.clients.connected_clients
    end

    -- nginx connections
    if string_find(procName, "NGINX_MASTER") then
        local client = http:new()
        local _, _, _, _, bodyStr = client:request{
            url = [[https://127.0.0.1/nginx_status]],
            method = "GET", 
        }
    end
    
    -- beanstalkd jobs
    if string_find(procName, "BEANSTALKD") then
        local beans = self:_getBeans()
        local res = beans:command("stats_tube", self._cmd.beanstalkd.jobTube)
        return string_match(res, "total%-jobs: (%d+)")
    end

    return 0
end

function WatchdogAction:_getBeans()
    if not self._beans then
        self._beans = self:_newBeans()
    end
    return self._beans 
end

function WatchdogAction:_newBeans()
    local beans = BeansService:create(self._cmd.config.beanstalkd)
    local ok, err = beans:connect()
    if err then
        throw("connect internal beanstalkd failed, %s", err)
    end
    return beans
end

function WatchdogAction:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function WatchdogAction:_newRedis()
    local redis = RedisService:create(self._cmd.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return WatchdogAction
