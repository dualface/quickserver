--require("framework.init")

-- create server app instance
--local config = require("server.config")
--local app = require("server.BackgroundWorkerApp").new(config)

local function run_()
    require("framework.init")

    local config = require("server.config")
    local app = require("server.BackgroundWorkerApp").new(config)

    app:run()
end

ngx.timer.at(0, run_)
