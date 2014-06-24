
require("server.lib.init")
require("server.lib.errors")

-- create server app instance
local config = require("server.config")
local app = require("server.TestServerApp").new(config)
--ngx.say("run...:")
app:run()
