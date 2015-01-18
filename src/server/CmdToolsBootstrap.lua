require("framework.init")
local config = require("server.config")
local args = {...}

local app = require("server.CmdToolsApp").new(config, args)
app:run()
