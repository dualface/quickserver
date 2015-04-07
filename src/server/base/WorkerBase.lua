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

local assert = assert
local type = type
local string_lower = string.lower

local ActionDispatcher = import(".ActionDispatcher")
local Constants = import(".Constants")

local WorkerBase = class("WorkerBase", ActionDispatcher)

function WorkerBase:ctor(config, arg)
    WorkerBase.super.ctor(self, config)

    self._requestType = Constants.WORKER_REQUEST_TYPE
    self._requestParameters = checktable(arg)
end

function WorkerBase:run()
    local ok, err = xpcall(function()
        self:runEventLoop()
    end, function(err)
        err = tostring(err)
        printError(err)
    end)
end

function WorkerBase:runEventLoop()
    local actionName = self._requestParameters[1]
    assert(type(actionName) == "string")
    assert(string_lower(actionName) == "jobworker.handle" or string_lower(actionName) == "monitor.watch")

    local resutl = self:runAction(actionName, self._requestParameters)
    printInfo("DONE")
end

return WorkerBase
