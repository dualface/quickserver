
local ChatAction = class("ChatAction")

function ChatAction:ctor(app)
    self._app = app
end

function ChatAction:sendmessageAction(arg)
    if not arg.dest then
        throw("not set argument: \"dest\"")
    end
    if not arg.message then
        throw("not set argument: \"message\"")
    end
    local dest = arg.dest
    local session = self._app:getSession()
    local message = {
        username = session:get("username"),
        message = arg.message,
        src = self._app:getConnectId()
    }
    self._app:sendMessageToConnect(dest, message)
end

return ChatAction
