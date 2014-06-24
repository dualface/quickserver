
local ChatWorker = class("ChatWorker", cc.server.ActionBase)

function ChatWorker:sendAction(data, job)
    local redis = self.app:getRedis()
    local uid, ch, msg = data.uid, data.ch, data.msg
    local uids, err = redis:command("smembers", ch)

    if err then
        return false
    end

    local results = {
        name = "chat",
        msg  = msg
    }

    self.app:newService("message"):batchSendMessageToUser(uids, results, uid)

    return true
end

return ChatWorker
