
-- define action obj, notice its name should be same to file name. 
local SayAction = class("SayAction", cc.server.ActionBase)

-- define actions, param 'data' is necessary. 
-- it means you can call this interface via uri '/prefix/Say/SayHello' 
function SayAction:SayHelloAction(data)

    -- use json lib 
    local jsonStr = json.encode(data.name) 
    return self:SayFunc(jsonStr)
end

-- another action
function SayAction:SayHiAction(data)

end

-- you can write other func
function TestsAction:SayFunc(jsonStr)
    local str = json.decode(jsonStr)

    -- return a table
    return {"hi": str.name} 
end

-- you can write more functions and codes, according to your requirement.
function SayAction:Funcs()
end

local function Funcs()
end

return SayAction
