
-- define action obj, notice its name should be same to file name.
local HelloworldAction = class("HelloworldAction", cc.server.ActionBase)

-- define actions, param 'data' is necessary.
-- it means you can call this interface via uri '../Helloworld/SayHello'
function HelloworldAction:SayhelloAction(data)
    return {hello_world = data.user}
end

-- another action
function HelloworldAction:SayhiAction(data)
    return {dont_want_say_hi = data.user}
end

return HelloworldAction
