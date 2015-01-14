if type(DEBUG) ~= "number" then DEBUG = 0 end

-- load framework
cc = cc or {}

require("framework.debug")
require("framework.functions")
require("framework.errors")
require("framework.package_support")
json = require("framework.json")

cc.server = {}
cc.server.ServerAppBase         = require("server.lib.ServerAppBase")
cc.server.WebSocketsServerBase  = require("server.lib.WebSocketsServerBase")
cc.server.HttpServerBase        = require("server.lib.HttpServerBase")
cc.server.CommandLineServerBase = require("server.lib.CommandLineServerBase")

-- register the build-in packages 
cc.register("event", require("framework.components.event"))
