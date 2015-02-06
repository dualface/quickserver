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
local _GET_CPU_PATTERN = "ps -p %s -o pcpu=" 
local _GET_MEM_PATTERN = "ps -p %s -o pmem="


local MaintainAction = class("Maintain") 

function MaintainAction:ctor(app)
    self._app = app 
    self.config.process = self.config.monitor.process

    self._procData = {}
end

function MaintainAction:monitorAction(arg)
    _getPid()
    _getPerfomance() 
    _save()
end

function MaintainAction:_save()
end

function MaintainAction:_getPerfomance()
end

function MaintainAction:_getPid()
    local process = self.config.process
    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()

        local pids = string_split(res, "\n")
        for _, pid in ipairs(pids) do
            self._procData[pid] = {}
        end
    end
end

return MaintainAction
