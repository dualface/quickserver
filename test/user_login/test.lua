--local COCOSCHINA = [[http://open.cocoachina.com/api/user_login]]
local COCOSCHINA = [[http://localhost:8088/_server/user/login]]

local http = require("resty.http")
local httpClient = http:new() 

local function LoginNormal_case1() 
    local ok, _, _, _, body = httpClient:request{
        url = COCOSCHINA, 
        method = "POST", 
        header = {["Content-Type"] = "application/json"},
        body = [[{"username":"hqycxy", "password":"hqycxylove1", "email":"cheeray.huang@gmail.com", "from":"OA"}]]
    }

    if not ok then 
        print("failed") 
    end 

    print(body.status) 
    print(body.msg)
    print("success")
end

LoginNormal_case1()
