
local arg = {...}

require("server.lib.init")
require("server.lib.errors")

-- create worker app instance
local config = require("server.config")
local app = require("server.TestWorkerApp").new(config, arg)
app:run()
