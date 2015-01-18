require("framework.init")

-- create server app instance
local config = require("server.config")
local app = require("server.CmdBroadcastWorkerApp").new(config)
app:run()
