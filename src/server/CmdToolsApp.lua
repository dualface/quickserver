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
