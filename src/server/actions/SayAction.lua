
-- define action obj, notice its name should be same to file name. 
local SayAction = class("SayAction", cc.server.ActionBase)

function SayAction:ctor(app)
end

-- define actions, param 'data' is necessary. 
-- it means you can call this interface via uri '/prefix/Say/SayHello' 
function SayAction:SayhelloAction(data)

    -- use json lib 
    local jsonStr = json.encode(data)
    return self:SayFunc(jsonStr)
end

-- another action
function SayAction:SayhiAction(data)

end

-- you can write other func
function SayAction:SayFunc(jsonStr)
    local tbl = json.decode(jsonStr)

    -- return a table
    return {hi_in_server = tbl.name}
end

-- you can write more functions and codes, according to your requirement.
function SayAction:Funcs()
end

local function Funcs()
end

return SayAction
