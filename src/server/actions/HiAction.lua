
-- define action obj, notice its name should be same to file name. 
local HiAction = class("HiAction", cc.server.ActionBase)

-- define actions, param 'data' is necessary. 
-- it means you can call this interface via uri '/prefix/Hi/SayHello' 
function HiAction:SayhelloAction(data)

    -- use json lib 
    local jsonStr = json.encode(data)
    return self:SayFunc(jsonStr)
end

-- another action
function HiAction:SayhiAction(data)

end

-- you can write other func
function HiAction:SayFunc(jsonStr)
    local tbl = json.decode(jsonStr)

    -- return a table
    return {real_hi = tbl.name}
end

-- you can write more functions and codes, according to your requirement.
function HiAction:Funcs()
end

local function Funcs()
end

return HiAction
