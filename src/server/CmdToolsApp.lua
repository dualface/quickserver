--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

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

local CmdToolsApp = class("CmdToolsApp", cc.server.CommandLineServerBase)

function CmdToolsApp:ctor(config, arg)
    CmdToolsApp.super.ctor(self, config)
    self.arg = arg
    self.config.actionPackage = "tools"
    self.config.actionModuleSuffix = "Tool"
end

function CmdToolsApp:doRequest(actionName, data)
    printf("> run tool %s\n", actionName)
    local ok, result = xpcall(function()
        return CmdToolsApp.super.doRequest(self, actionName, data)
    end, function(msg)
        return msg .. "\n" .. debug.traceback("", 4)
    end)
    if not ok then
        printf("> error: %s\n", result)
    end
end

function CmdToolsApp:runEventLoop()
    local actionName = self.arg[1]
    if not actionName then actionName = "help" end
    local arg = clone(self.arg)
    table.remove(arg, 1)
    return self:doRequest(actionName, arg)
end

return CmdToolsApp
