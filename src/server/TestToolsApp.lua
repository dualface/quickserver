
local TestToolsApp = class("TestToolsApp", cc.server.CommandLineServerBase)

function TestToolsApp:ctor(config, arg)
    TestToolsApp.super.ctor(self, config)
    self.arg = arg
    self.config.actionPackage = "tools"
    self.config.actionModuleSuffix = "Tool"
end

function TestToolsApp:doRequest(actionName, data)
    printf("> run tool %s\n", actionName)
    local ok, result = xpcall(function()
        return TestToolsApp.super.doRequest(self, actionName, data)
    end, function(msg)
        return msg .. "\n" .. debug.traceback("", 4)
    end)
    if not ok then
        printf("> error: %s\n", result)
    end
end

function TestToolsApp:runEventLoop()
    local actionName = self.arg[1]
    if not actionName  then actionName = "help" end
    local arg = clone(self.arg)
    table.remove(arg, 1)
    return self:doRequest(actionName, arg)
end

return TestToolsApp
