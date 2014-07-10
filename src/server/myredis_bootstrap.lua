require("server.lib.init")
require("server.lib.errors")

local config = {
        host       = "127.0.0.1",
        port       = 6379,
        timeout    = 10 * 1000, -- 10 seconds
}

function NewRedis()
    local redis = cc.server.RedisEasy.new(config)
    local ok, err = redis:connect()
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, "failed to connect redis, %s", err)
    end
    return redis
end

local rds = NewRedis(config)

local res, err = rds:command("zcard", "myzset")
if err then 
    throw(ERR_SERVER_OPERATION_FAILED, "failed to exec zcard: %s", err)    
end
ngx.say("res: "..res)

res, err = rds:command("zcount", "myzset", "(1", 3)
if err then 
    throw(ERR_SERVER_OPERATION_FAILED, "failed to exec zcount: %s", err)    
end
ngx.say("res: "..res)

res, err = rds:command("zrange", "myzset", 0, 2)
if err then 
    throw(ERR_SERVER_OPERATION_FAILED, "failed to exec zrange: %s", err)    
end
for k, v in pairs(res) do 
    ngx.say("res: "..k .. " :" .. v)
end 

res, err = rds:command("zrank", "myzset", "qjj")
if err then 
    ngx.say(err)
end 
--ngx.say("res: ".. res)

res, err = rds:command("zrangebyscore", "myzset", -1, 10.7)
local res_ = {}
for _, v in pairs(res) do
    res_[v] = rds:command("zscore", "myzset", v)
end
ngx.say("res = {")
for k,v in pairs(res_) do 
    ngx.say(k .. " :" .. v)
end
ngx.say("}")


