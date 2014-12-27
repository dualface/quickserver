
-- define action obj, notice its name should be same to file name. 
local HelloworldAction = class("HelloworldAction", cc.server.ActionBase)

-- define actions, param 'data' is necessary. 
-- it means you can call this interface via uri '../Helloworld/SayHello' 
function HelloworldAction:SayhelloAction(data)

    -- use json lib 
    local jsonStr = json.encode(data)
    return self:SayFunc(jsonStr)
end

-- another action
function HelloworldAction:SayhiAction(data)
    
    return {dont_want_say_hi = data.name}
end

-- you can write other func
function HelloworldAction:SayFunc(jsonStr)
    local tbl = json.decode(jsonStr)

    -- return a table
    return {hello_world = tbl.name}
end

-- you can write more functions and codes, according to your requirement.
function HelloworldAction:Funcs()
end

local function Funcs()
end

return HelloworldAction
