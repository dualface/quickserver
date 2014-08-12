--[[require("server.lib.init")
require("server.lib.errors")

-- create server app instance
local config = require("server.config")
local app = require("server.HttpServerApp").new(config)
app:run()
--]]


local function merge(dest, src) 
    for k,v in pairs(src) do 
        dest[k] = v
    end
end

ngx.req.read_body()
local args, err = ngx.req.get_post_args()
if not args then
    ngx.say("failed to get post args: ", err)
    return
end

local args2, err = ngx.req.get_uri_args()
if args2 then
    merge(args, args2)
end

for key, val in pairs(args) do
    if type(val) == "table" then
        ngx.say(key, ": ", table.concat(val, ", "))
    else
        ngx.say(key, ": ", val)
    end
end
