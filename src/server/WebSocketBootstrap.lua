require("framework.init")

-- create server app instance
local config = require("server.config")
local app = require("server.WebSocketServerApp").new(config)
app:run()
