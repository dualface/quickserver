
local ok, socket = pcall(function()
    return require("socket")
end)

if ok then
    math.randomseed(socket.gettime() * 1000)
else
    math.randomseed(os.time())
end
math.random()
math.random()
math.random()
math.random()

if type(DEBUG) ~= "number" then DEBUG = 1 end
local CURRENT_MODULE_NAME = ...

-- init shared framework modules
cc = cc or {}
cc.PACKAGE_NAME = string.sub(CURRENT_MODULE_NAME, 1, -6)
cc.VERSION = "2.0.0"
cc.FRAMEWORK_NAME = "quick-cocos2d-x server"

require("framework.debug")
require("framework.functions")
require("framework.package_support")
json = require("framework.json")

require(cc.PACKAGE_NAME .. ".functions")
require(cc.PACKAGE_NAME .. ".errors")

cc.server = {}
cc.server.ServerAppBase         = require(cc.PACKAGE_NAME .. ".ServerAppBase")
cc.server.WebSocketsServerBase  = require(cc.PACKAGE_NAME .. ".WebSocketsServerBase")
cc.server.HttpServerBase        = require(cc.PACKAGE_NAME .. ".HttpServerBase")
cc.server.CommandLineServerBase = require(cc.PACKAGE_NAME .. ".CommandLineServerBase")
cc.server.ActionBase            = require(cc.PACKAGE_NAME .. ".ActionBase")
cc.server.Session               = require(cc.PACKAGE_NAME .. ".Session")
cc.server.RedisEasy             = require(cc.PACKAGE_NAME .. ".RedisEasy")
cc.server.BeanstalkdEasy        = require(cc.PACKAGE_NAME .. ".BeanstalkdEasy")
cc.server.MysqlEasy             = require(cc.PACKAGE_NAME .. ".MysqlEasy")
--cc.server.RankList              = require(cc.PACKAGE_NAME .. ".RankList")
cc.server.http                  = require(cc.PACKAGE_NAME .. ".http")
cc.server.url                   = require(cc.PACKAGE_NAME .. ".url")

-- init base classes
cc.Registry   = require("framework.cc.Registry")
cc.GameObject = require("framework.cc.GameObject")

-- init components
local components = {
    "components.behavior.StateMachine",
    "components.behavior.EventProtocol",
}
for _, packageName in ipairs(components) do
    cc.Registry.add(require("framework.cc." .. packageName), packageName)
end

-- init MVC
cc.mvc = {}
cc.mvc.ModelBase = require("framework.cc.mvc.ModelBase")
