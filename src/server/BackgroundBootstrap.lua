require("framework.init")

-- create server app instance
local config = require("server.config")
local app = require("server.BackgroundWorkerApp").new(config)
app:run()
