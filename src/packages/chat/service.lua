local tabLength = table.nums
local jsonEncode = json.encode

local ChatService = class("ChatService")

function ChatService:ctor(app)
    local config = nil
    if app then 
        config = app.config.redis
    end
    self.redis = cc.load("redis").service.new(config)
    self.redis:connect()

    self.channel = app.chatChannel
end

local function checkParams_(data, ...)
    local arg = {...} 

    if tabLength(arg) == 0 then 
        return true
    end 
    
    for _, name in pairs(arg) do 
        if data[name] == nil or data[name] == "" then 
           return false 
        end 
    end 

    return true 
end

function ChatService:broadcast(data)
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end 

    if not checkParams_(data, "payload", "nickname") then 
        return nil, "'payload' or 'nickname' is missed in param table."
    end 
    
    local channel = self.channel
    rds:command("publish", channel, jsonEncode(data))

    return channel, nil
end

return ChatService
