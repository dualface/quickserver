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
local io

local MaintainAction = class("Maintain") 

function MaintainAction:ctor(app)
    self._app = app 
    self.config.process = self.config.monitor.process

    self._pid = {}
    self._data = {}
end

function MaintainAction:monitorAction(arg)
    _getPid()
    
end

function MaintainAction:_getPid(process)
    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        fout:close()
        self._pid[procName] = string_split(res, "\n")
    end
end

return MaintainAction
