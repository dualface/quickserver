
local MessageService = class("MessageService")

function MessageService:ctor(app)
    self.app = app
end

function MessageService:batchSendMessageToUser(uids, message)
    local redis =  self.app:getRedis()
    if type(message) == "table" then
        message = json.encode(message)
    end

    local pipeline = redis:newPipeline()
    for i, uid in pairs(uids) do
        local channel = string.format(ONLINE_USERS_CHANNEL_PATTERN, uid)
        pipeline:command("publish", channel, message)
    end
    pipeline:commit()
end

return MessageService
