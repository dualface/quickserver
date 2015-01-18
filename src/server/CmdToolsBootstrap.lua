require("framework.init")
local config = require("server.config")
local args = {...}

local app = require("server.CmdToolsServerApp").new(config, args)
app:run()
