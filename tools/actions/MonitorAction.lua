--[[

Copyright (c) 2011-2015 dualface#github

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
local tostring = tostring
local string_format = string.format
local string_find = string.find
local string_sub = string.sub
local string_upper = string.upper
local string_split = string.split
local string_match = string.match
local table_insert = table.insert
local table_concat = table.concat
local math_trunc = math.trunc
local io_popen = io.popen

local _RESET_REDIS_CMD = [[_QUICK_SERVER_ROOT_/bin/redis/bin/redis-server _QUICK_SERVER_ROOT_/bin/redis/conf/redis.conf]]
local _RESET_NGINX_CMD = [[nginx -p _QUICK_SERVER_ROOT_ -c _QUICK_SERVER_ROOT_/bin/openresty/nginx/conf/nginx.conf]]
local _RESET_BEANSTALKD_CMD = [[_QUICK_SERVER_ROOT_/bin/beanstalkd/bin/beanstalkd > _QUICK_SERVER_ROOT_/logs/beanstalkd.log &]]

local _GET_MEM_INFO_CMD = [[cat /proc/meminfo | grep -E "Mem(Free|Total)"]]
local _GET_DISK_INFO_CMD = [[df --total -k | grep "total"]]
local _GET_CPU_INFO_CMD = [[cat /proc/cpuinfo | grep "cpu cores"]]

local _GET_PID_PATTERN = "pgrep %s"
local _GET_PERFORMANCE_PATTERN = [[top -b -n 1 -p%s]]

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_LIST_PATTERN = "_MONITOR_%s_%s_LIST"
local _MONITOR_MEM_INFO_KEY = "_MONITOR_MEM_INFO"
local _MONITOR_CPU_INFO_KEY = "_MONITOR_CPU_INFO"
local _MONITOR_DISK_INFO_KEY = "_MONITOR_DISK_INFO"

-- since this tool is running background as a loop,
-- redis connection don't need closing.
local RedisService = cc.load("redis").service

local BeansService = cc.load("beanstalkd").service

local httpClient = require("httpclient").new()

local socket = require("socket")

local MonitorAction = class("Monitor")

function MonitorAction:ctor(cmd)
    self._cmd = cmd
    self._process = cmd.config.monitor.process
    self._interval = cmd.config.monitor.interval
    self._procData = {}
    self._memThreshold = cmd.config.mem
    self._cpuThreshold = cmd.config.cpu

    self._minuteListLen = 0
    self._secListLen = 0
    self._hourListLen = 0
end

function MonitorAction:watchAction(arg)
    local sock = require("socket")
    local elapseSec = 0
    local elapseMin = 0
    local interval = self._interval

    self:_initList()

    self:_getCpuInfo()
    self:_getMemInfo()
    self:_getDiskInfo()

    while true do
        local timer1 = socket.gettime()
        self:_getPid()
        self:_getPerfomance()

        self:_save(math_trunc(elapseSec/60), math_trunc(elapseMin/60))
        local timer2 = socket.gettime()

        local dTime = timer2 - timer1
        if interval - dTime > 0 then
            sock.sleep(interval-dTime)
        end

        if elapseSec >= 60 then
            elapseSec = elapseSec % 60
        end
        if elapseMin >= 60 then
            elapseMin = elapseMin % 60
        end
        elapseSec = elapseSec + interval
        elapseMin = elapseMin + (math_trunc(elapseSec / 60))
    end
end

function MonitorAction:_initList()
    self:_getPid()

    local pipe = self:_getRedis():newPipeline()
    for k, _ in pairs(self._procData) do
        pipe:command("DEL", string_format(_MONITOR_LIST_PATTERN, k, "SEC"))
        pipe:command("DEL", string_format(_MONITOR_LIST_PATTERN, k, "MINUTE"))
        pipe:command("DEL", string_format(_MONITOR_LIST_PATTERN, k, "HOUR"))
    end
    pipe:commit()
end

function MonitorAction:_getCpuInfo()
    local fout = io_popen(_GET_CPU_INFO_CMD)
    local res = string_match(fout:read("*a"), "cpu cores.*: (%d+)")
    fout:close()

    local redis = self:_getRedis()
    redis:command("SET", _MONITOR_CPU_INFO_KEY, res)

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
    local total, free = string_match(fout:read("*a"), "total%s+(%d+)%s+%d+%s+(%d+).*")
    fout:close()

    local redis = self:_getRedis()
    redis:command("SET", _MONITOR_DISK_INFO_KEY, total .. "|" .. free)
end

function MonitorAction:_save(isUpdateMinList, isUpdateHourList)
    local maxSecLen = 60 / self._interval

    local pipe = self:_getRedis():newPipeline()
    for k, v in pairs(self._procData) do
        local secListLen = self._secListLen
        local minuteListLen = self._minuteListLen
        local hourListLen = self._hourListLen
        local data = v.cpu .. "|" .. v.mem .. "|" .. v.conn

        local list = string_format(_MONITOR_LIST_PATTERN, k, "SEC")
        pipe:command("RPUSH", list, data)
        if secListLen > maxSecLen then
            pipe:command("LPOP", list)
        end

        if isUpdateMinList ~= 0 then
            list = string_format(_MONITOR_LIST_PATTERN, k, "MINUTE")
            pipe:command("RPUSH", list, data)
            if minuteListLen > 60 then
                pipe:command("LPOP", list)
            end
        end

        if isUpdateHourList ~= 0 then
            list = string_format(_MONITOR_LIST_PATTERN, k, "HOUR")
            pipe:command("RPUSH", list, data)
            if hourListLen > 24 then
                pipe:command("LPOP", list)
            end
        end
    end
    pipe:commit()

    if self._secListLen <= maxSecLen then
        self._secListLen = self._secListLen + 1
    end
    if isUpdateMinList ~= 0 and self._minuteListLen <= 60 then
        self._minuteListLen = self._minuteListLen + 1
    end
    if isUpdateHourList ~= 0 and self._hourListLen <= 24 then
        self._hourListLen = self._hourListLen + 1
    end
end

function MonitorAction:_getPerfomance()
    -- get cpu%, mem via top
    local pids = {}
    for _, v in pairs (self._procData) do
        table_insert(pids, v.pid)
    end
    local strPids = table_concat(pids, ",")

    local cmd = string_format(_GET_PERFORMANCE_PATTERN, strPids)
    local fout = io_popen(cmd)
    local topRes = string_split(fout:read("*a"), "\n")
    fout:close()

    local filterRes = {}
    for i = #topRes-#pids+1, #topRes do
        local t = string_split(topRes[i], " ")
        filterRes[t[1]] = {t[9], t[6]}
    end

    for k, v in pairs(self._procData) do
        local pid = v.pid
        if filterRes[pid] then
            v.cpu = filterRes[pid][1]
            v.mem = filterRes[pid][2]
            v.conn = self:_getConnNums(k)
        else
            v.cpu = "0.0"
            v.mem = "0"
            v.conn = "0"
        end
    end

    if DEBUG >= 1 then
        for k, v in pairs(self._procData) do
            printInfo("%s pid %s: cpu %s, mem %s", k, v.pid, v.cpu, v.mem)
            if tonumber(v.cpu) > 100 then
                printWarn("cpu usage %s of %s is large than 100", v.cpu, k)
            end
        end
    end
end

function MonitorAction:_getPid()
    local process = self._process
    local pipe = self:_getRedis():newPipeline()
    pipe:command("DEL", _MONITOR_PROC_DICT_KEY)
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
            end

            self._procData[pName] = {}
            self._procData[pName].pid = pid
            pipe:command("HSET", _MONITOR_PROC_DICT_KEY, pName, pid)
        end
    end
    pipe:commit()
end

function MonitorAction:_resetProcess(procName)
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

function MonitorAction:_getConnNums(procName)
    -- redis connections.
    if string_find(procName, "REDIS%-SERVER") then
        local redis = self:_getRedis()
        res = redis:command("INFO")
        return res.clients.connected_clients
    end

    -- nginx connections
    if string_find(procName, "NGINX_MASTER") then
        local res = httpClient:get("http://localhost:" .. tostring(self._cmd.config.port) .. "/nginx_status")
        if res.body then
            return string_match(res.body, "connections: (%d+)")
        else
            printWarn("access nginx_status failed, err: %s", res.err)
            return -1
        end
    end

    -- beanstalkd jobs
    if string_find(procName, "BEANSTALKD") then
        local beans = self:_getBeans()
        local ok, res = pcall(beans.command, beans, "stats_tube", self._cmd.config.beanstalkd.jobTube)
        if not ok then
            return "0"
        else
            return string_match(res, "total%-jobs: (%d+)")
        end
    end

    return 0
end

function MonitorAction:_getBeans()
    if not self._beans then
        self._beans = self:_newBeans()
    end
    return self._beans
end

function MonitorAction:_newBeans()
    local beans = BeansService:create(self._cmd.config.beanstalkd)
    local ok, err = beans:connect()
    if err then
        throw("connect internal beanstalkd failed, %s", err)
    end
    return beans
end

function MonitorAction:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function MonitorAction:_newRedis()
    local redis = RedisService:create(self._cmd.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return MonitorAction
