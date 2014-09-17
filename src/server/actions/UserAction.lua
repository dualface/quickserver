
local ERR_USER_INVALID_PARAM = 3000
local ERR_USER_OPERATION_FAILED = 3100

local SECRET = [[a6733a8e68960921f9dea6d2080c722b]]

local UserAction = class("UserAction", cc.server.ActionBase)

local function Err(errCode, errMsg, ...)
    local msg = string.format(errMsg, ...)

    return {err_code = errCode, err_msg=msg}
end

-- actually, this function is only for test. 
-- In practice, client should offer password coded by MD5.
local function IsMD5(password)
    if string.len(password) ~= 32 then 
        return false
    end

    for i = 1, 32 do 
        if not tonumber(string.sub(password, i, i), 16) then 
            return false
        end
    end

    return true
end

local function ConstructBody(body) 
    if not IsMD5(body.password) then 
        body.password = ngx.md5(body.password)    
    end

    local str = SECRET
    for k, v in body do
        str = str .. k .. v
    end
    body.sign = string.upper(ngx.md5(str .. SECRET))

    local bodyStr = json.encode(body)
    echoInfo("Login Body = %s", bodyStr)
   
    return bodyStr 
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

    local email = data.email
    if email == nil or type(email) ~= string then 
        self.reply = Err(ERR_USER_INVALID_PARAM, "param(email) is missed")
        return self.reply
    end

    local httpClient = cc.server.http:new()
    
    local bodyStr = nil 
    local reqBody = {}
    local ok = nil
    local err = nil

    reqBody.user = user 
    reqBody.password = password
    reqBody.from = from 
    reqBody.email = email 
    reqBody.time = os.time()

    ok, _, _, _, bodyStr = httpClient:request{
        url = [[http://open.cocoachina.com/api/user_login]], 
        method = "POST", 
        header = { ["Content-Type"] = "application/json"}, 
        body = ConstructBody(reqBody)
    } 

    if not ok then 
        self.reply = Err(ERR_USER_OPERATION_FAILED, "operation User.Login failed: access cocoschina interface failed")
        return self.reply
    end

    local body = json.decode(bodyStr) 
    if body.status == "error" then 
        self.reply =Err(ERR_USER_OPERATION_FAILED, "operation User.Login failed: username or passwrod is wrong.")
        return self.reply
    end

    body = json.decode(body.msg)
    local ip = ngx.var.remote_addr
    local session_id = ngx.md5(body.uid .. ":" .. body.ip .. ":" .. tostring(time))
    
    local findSql = string.format([[insert into table(uid, session_id, ip) value('%s', '%s', '%s') on duplicate key update session_id = '%s', ip = '%s';]], body.uid, session_id, ip, session_id, ip)
    ok, err = self.Mysql:query(findSql)
    if not ok then 
        self.reply = Err(ERR_USER_OPERATION_FAILED, "operation User.Login failed: Store user info failed.")
        return self.reply
    end

    -- set expired time of session_id in redis
    ok = self.Redis:command("hset", "__token_expire", body.uid, time)
    echoInfo("redis OK = %s", ok)

    self.reply = {session_id = session_id, uid = body.uid}
    return self.reply
end

return UserAction 
