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
local string_sub = string.sub
local string_lower = string.lower
local table_insert = table.insert
local math_trunc = math.trunc
local io_popen = io.popen

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_LIST_PATTERN = "_MONITOR_%s_%s_LIST"

local _GET_MEM_TOTAL_CMD = [[cat /proc/meminfo | grep "MemTotal"]]

local MonitorAction = class("MonitorAction")

function MonitorAction:ctor(connect)
    self.connect = connect
    self._interval = connect.config.monitor.interval
    self._redis = connect:getRedis()
end

function MonitorAction:getalldataAction(arg)
    local result = {}
    local process = self:_getProcess()
    for _, procName in ipairs(process) do
        result[procName] = self:_fillData(procName, {"SEC", "MINUTE", "HOUR"}, 0)
    end

    result.interval = self._interval
    result.mem_total = self:_getMemTotal()

    return result
end

function MonitorAction:getdataAction(arg)
    local timeSpan = self:_convertToSec(arg.time_span)

    if not timeSpan or timeSpan <= 0 then
        return self:getalldataAction(arg)
    end

    local listType = {}
    local start = 0
    if timeSpan <= 600 then
        table_insert(listType, "SEC")
        start = -math_trunc(timeSpan / self._interval)
    elseif timeSpan <= 3600 then
        table_insert(listType, "MINUTE")
        start = -math_trunc(timeSpan / 60)
    else
        table_insert(listType, "HOUR")
        start = -math_trunc(timeSpan / 3600)
    end

    local result = {}
    local process = self:_getProcess()
    for _, procName in ipairs(process) do
        result[procName] = self:_fillData(procName, listType, start)
    end

    result.interval = self._interval
    result.mem_total = self:_getMemTotal()

    return result
end

function MonitorAction:_getProcess()
    local redis = self._redis
    local process = redis:command("HKEYS", _MONITOR_PROC_DICT_KEY)

    return process
end

function MonitorAction:_getMemTotal()
    local fout = io_popen(_GET_MEM_TOTAL_CMD)
    local res = string_match(fout:read("*a"), "(%d+) kB")
    fout:close()

    return res
end

function MonitorAction:_convertToSec(timeSpan)
    local time = string_match(string_lower(timeSpan), "^(%d+[s|h|m])")
    local unit = string_sub(time, -1)
    local number = string_sub(time, 1, -2)

    if unit == "h" then
        return tonumber(number) * 3600
    end

    if unit == "m" then
        return tonumber(number)*60
    end

    if unit == "s" then
        return tonumber(number)
    end

    return nil
end

function MonitorAction:_fillData(procName, listType, start)
    local redis = self._redis
    local t = {}
    t.mem = {}
    t.cpu = {}
    t.conn_num = {}

    for _, typ in ipairs(listType) do
        local list = string_format(_MONITOR_LIST_PATTERN, procName, typ)
        local data = redis:command("LRANGE", list, start, -1)
        local field = self:_getFiled(typ)
        for _, v in ipairs(data) do
            local tmp = string_split(v, "|")
            table_insert(t.cpu[field], tmp[1])
            table_insert(t.mem[field], tmp[2])
            table_insert(t.conn_num[field], tmp[3])
        end
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
