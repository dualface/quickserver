local ChatAction = class("ChatAction")

local function err_(...)
    return {err_msg = strFormat(...)}
end

local service = import(".service")

function ChatAction:ctor(app)
    self.chatService = service.new(app)
end

function ChatAction:broadcastAction(data)
    local s = self.chatService
    if not s then
        return err_("chatAction is not initialized.")
    end

    local channel, err = s:broadcast(data)
    if not channel then 
        return err_(err)
    end

    return {ok = 1, channel = channel}
end

return ChatAction
