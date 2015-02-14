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
local string_match = string.match
local io_popen = io.popen

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_CPU_LIST_PATTERN = "_MONITOR_%s_CPU_%s_LIST"
local _MONITOR_MEM_LIST_PATTERN = "_MONITOR_%s_MEM_%s_LIST"

local _GET_MEM_TOTAL_CMD = [[cat /proc/meminfo | grep "MemTotal"]]

local MonitorAction = class("MonitorAction")

function MonitorAction:ctor(connect)
    self.connect = connect
    self._redis = connect:getRedis()
end

function MonitorAction:getdataAction(arg)
    local result = {}
    local redis = self._redis
    local process = redis:command("HKEYS", _MONITOR_PROC_DICT_KEY)
    for _, procName in ipairs(process) do
        if tonumber(procName) == nil then
            result[procName] = self:_fillData(procName)
        end
    end

    result.interval = self.connect.config.monitor.interval
    local fout = io_popen(_GET_MEM_TOTAL_CMD)
    result.mem_total = string_match(fout:read("*a"), "(%d+) kB")
    fout:close()

    return result
end

function MonitorAction:_fillData(procName)
    local listType = {"SEC", "MINUTE", "HOUR"}
    local redis = self._redis
    local t = {}
    t.mem = {}
    t.cpu = {}

    for _, typ in ipairs(listType) do
        local cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, procName, typ)
        local memList = string_format(_MONITOR_MEM_LIST_PATTERN, procName, typ)
        local field = self:_getFiled(typ)
        t.cpu[field] = redis:command("LRANGE", cpuList, 0, -1)
        t.mem[field] = redis:command("LRANGE", memList, 0, -1)
    end

    return t
end

function MonitorAction:_getFiled(typ)
    if typ == "SEC" then
        return "last_600s"
    end

    if typ == "MINUTE" then
        return "last_hour"
    end

    if typ == "HOUR" then
        return "last_day"
    end
end

return MonitorAction
