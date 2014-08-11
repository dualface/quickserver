--[[
require("server.lib.init")
require("server.lib.errors")

-- create server app instance
local config = require("server.config")
local app = require("server.HttpServerApp").new(config)
--ngx.say("run...:")
app:run()
--]]

ngx.req.read_body()
local args, err = ngx.req.get_post_args()
if not args then
    ngx.say("failed to get post args: ", err)
    return
end
for key, val in pairs(args) do
    if type(val) == "table" then
        ngx.say(key, ": ", table.concat(val, ", "))
    else
        ngx.say(key, ": ", val)
    end
end
