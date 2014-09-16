
local ERR_USER_INVALID_PARAM = 3000
local ERR_USER_OPERATION_FAILED = 3100

local UserAction = class("UserAction", cc.server.ActionBase)

local function Err(errCode, errMsg, ...)
    local msg = string.format(errMsg, ...)

    return {err_code = errCode, err_msg=msg}
end

function UserAction:ctor(app) 
    self.super:ctor(app)    

    self.Mysql = nil 
    self.Redis = nil

    if app then 
        self.Mysql = app.getMysql(app)
        self.Redis = app.getRedis(app)
    end  

    self.reply = {}
end

function UserAction:dector(app)
    if self.Mysql then 
        self.Mysql:close()
    end

    if self.Redis then
        self.Redis:close()
    end
end

function UserAction:LoginAction(data) 
    assert(type(data) == "table", "data is NOT a table.")

    local user = data.user
    if user == nil or type(user) ~= string then 
        self.reply = Err(ERR_USER_INVALID_PARAM, "param(user) is missed")
        return self.reply
    end

    local password = data.password 
    if password == nil or type(password) ~= string then 
        self.reply = Err(ERR_USER_INVALID_PARAM, "param(password) is missed")
        return self.reply
    end

    local from = data.from 
    if from == nil or type(from) ~= string then 
        self.reply = Err(ERR_USER_INVALID_PARAM, "param(from) is missed")
        return self.reply
    end

    local httpClient = cc.server.http:new()
    
    local bodyStr = nil 
    local ok = nil
    ok, _, _, _, bodyStr = httpClient:request{

    } 

    if not ok then 
        self.reply = Err(ERR_USER_OPERATION_FAILED, "access cocoschina interface failed")
        return self.reply
    end

    local body = json.decode(bodyStr) 
    if body.status == "error" then 
        self.reply =Err(ERR_USER_OPERATION_FAILED, "Login failed: username or passwrod is wrong.")
        return self.reply
    end

    local findSql = string.format([[select * from user_info where uid = %s]], body.uid)

    local res, err = self.Mysql:query(findSql)
    if not res then 
        self.reply = Err(ERR_USER_OPERATION_FAILED, "operation User.Login failed: %s", err)
        return self.reply
    end 
end

return UserAction 
