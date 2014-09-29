
local TestsAction = class("TestsAction", cc.server.ActionBase)

function TestsAction:ctor(app)
    self.super:ctor(app)

    self.redis = app.getRedis(app)
end

function TestsAction:IndexAction(data)
    --[[
    if not self.app.count then self.app.count = 0 end
    self.app.count = self.app.count + 1
    return {ret = string.format("SHOW ME THE MONEY [%s:%d]", data.say, self.app.count)}
    --]]
    
    local res, ok = self.redis:command("zrangebyscore", "srted_demo", 1, 3, "withscores")

    if not res then 
        return {error = "redis error"}
    end
    
    local i = 2
    local str = ""
    for i = 2, #res, 2 do
        str = str .. res[i]
    end

    return {res = str }
end

function TestsAction:ConstructParams(rawdata)
    local sha1_bin
    local bas64
    if ngx then 
        sha1_bin = ngx.sha1_bin
        base64 = ngx.encode_base64
    else 
        throw(ERR_SERVER_UNKNOWN_ERROR, "ngx is nil")
    end

    local body = {}
    for _, t in pairs(rawdata) do 
        if t.index == 1 then 
        end 

        for k, v in pairs(t) do
            body[k] = v
        end
    end 
    local id = sha1_bin(json.encode(body))

    return {id=base64(id), body=body} 
end

return TestsAction
