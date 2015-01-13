
local ServerAppBase = import(".ServerAppBase")

local CommandLineServerBase = class("CommandLineServerBase", ServerAppBase)

function CommandLineServerBase:ctor(config, arg)
    CommandLineServerBase.super.ctor(self, config)

    self.config.requestType = "commandline"
    self.requestParameters = totable(arg)
end

return CommandLineServerBase
