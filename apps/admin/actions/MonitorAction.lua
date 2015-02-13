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

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_CPU_LIST_PATTERN = "_MONITOR_%s_CPU_%s_LIST"
local _MONITOR_MEM_LIST_PATTERN = "_MONITOR_%s_MEM_%s_LIST"

local MonitorAction = class("MonitorAction")

function MonitorAction:ctor(connect)
    self.connect = connect
end

function MonitorAction:getdataAction(arg)
    local isGetAll = arg.is_get_all
    local redis = self.connect:getRedis()

    local process = redis:command("HGETALL", _MONITOR_PROC_DICT_KEY)
    local result = {}
    for i = 1, #res, 2 do
        local pid = process[i]
        local procName = process[i+1]
        result[procName] = {}
        _fillData(pid, result[procName])
    end

    return result
end

function MonitorAction:_fillData(pid, t)
    local listType = {"SEC", "MINUTE", "HOUR"}
    t.mem = {}
    t.cpu = {}

    for _, typ in ipairs(listType) do
        local cpuList = string_format(_MONITOR_CPU_LIST_PATTERN, pid, typ)
        local memList = string_format(_MONITOR_MEM_LIST_PATTERN, pid, typ)
        t.cpu[typ] = redis:command("LRANGE", 0, cpuList, 600)
        t.mem[typ] = redis:command("LRANGE", 0, memList, 600)
    end

    return t
end

return MonitorAction
