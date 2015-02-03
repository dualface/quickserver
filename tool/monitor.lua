local config = require("conf.config")

local function _init()
    config = config.monitor or {}
    config.cpu = config.monitor.cpu or {warning = 60, critical = 80}
    config.mem = config.monitor.mem or {warning = 70, critical = 90}
end

