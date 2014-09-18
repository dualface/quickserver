require("server.lib.init")
require("server.lib.errors")

local hc = cc.server.http:new()

local ok, code, headers, status, body  = hc:request {
    url = "http://baidu.com",
    --- proxy = "http://127.0.0.1:8888",
    --- timeout = 3000,
    method = "POST", -- POST or GET
    -- add post content-type and cookie
    headers = { Cookie = {"ABCDEFG"}, ["Content-Type"] = "application/x-www-form-urlencoded" },
    body = "uid=1234567890",
}

ngx.say(ok)
ngx.say(code)
ngx.say(body)
