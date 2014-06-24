
local TestsAction = class("TestsAction", cc.server.ActionBase)

function TestsAction:indexAction(data)
    --[[
    if not self.app.count then self.app.count = 0 end
    self.app.count = self.app.count + 1
    return {ret = string.format("SHOW ME THE MONEY [%s:%d]", data.say, self.app.count)}
    --]]

   jsonStr = json.encode(data.rawdata) 
   return self:ConstructParams(data.rawdata)
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
