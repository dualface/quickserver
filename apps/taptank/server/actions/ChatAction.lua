
local ChatAction = class("ChatAction")

function ChatAction:ctor(app)
    self._app = app
end

function ChatAction:sendmessageAction(arg)
    if not arg.tag then
        throw("not set argument: \"tag\"")
    end
    if not arg.message then
        throw("not set argument: \"message\"")
    end
    local tag = arg.tag
    local connectId = self._app:getConnectIdByTag(tag)
    if connectId then
        local session = self._app:getSession()
        local message = {
            username = session:get("username"),
            message = arg.message,
            tag = self._app:getConnectTag()
        }
        self._app:sendMessageToConnect(connectId, json.encode(message))
    else
        printWarn("not found connect id for tag \"%s\"", tag)
    end
end

return ChatAction
