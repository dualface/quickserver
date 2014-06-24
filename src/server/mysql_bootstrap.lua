require("server.lib.init")
require("resty.mysql")

--echoInfo("hello mysql!!")

local mysqlConfig = {
    host       = "127.0.0.1",
    port       = 3306,
    database   = "testdb",
    user       = "test",
    password   = "123456",
    timeout    = 10 * 1000,
}

function newMysql(config)
    local mysql, err = cc.server.MysqlEasy.new(config or self.config.mysql)

    if err then
        throw(ERR_SERVER_OPERATION_FAILED, "failed to connect mysql, %s", err)
    end

    return mysql
end

local params = {
    id = "test_idxxxxxxxx", 
    body = "this is a body for test.",
}

local mysql = newMysql(mysqlConfig)

--[[
local ok, err = mysql:insert("counter", params)
if not ok then 
    throw(ERR_SERVER_MYSQL_ERROR, "failed to insert data into mysql: %s", err)
end
--]]

local ok, err = mysql:query("select * from counter where id = 'test_idxxxxxxxx';")
ngx.say("query it, obj = ", json.encode(ok))

mysql:close()

ngx.say("finish.")

--[[
local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.say("failed to instantiate mysql: ", err)
    return
end

db:set_timeout(1000)

local ok, err, errno, sqlState = db:connect(mysqlConfig)

if not ok then 
    ngx.say("failed to connect to mysql: ", err) 
end

ngx.say("connect to mysql")
--]]


