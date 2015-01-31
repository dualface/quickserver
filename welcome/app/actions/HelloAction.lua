
local HelloAction = class("HelloAction")

function HelloAction:ctor(app)
    self._app = app
end

function HelloAction:sayAction(arg)
    local name = arg.name or "quickserver"
    return string.format("hello, %s", name)
end

function HelloAction:loginAction(arg)
    if not arg.username then
        throw("not set argument: \"username\"")
    end
    local session = self._app:startSession()
    session:set("username", arg.username)
    session:set("count", 0)
    session:save()
    return {sid = session:getSid(), count = session:get("count")}
end

function HelloAction:logoutAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    self._app:destroySession(arg.sid)
    return {ok = "ok"}
end

function HelloAction:countAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    local session = self._app:startSession(arg.sid)
    if session then
        local count = session:get("count")
        count = count + 1
        session:set("count", count)
        session:save()
        return {count = count}
    else
        throw("session is expired")
    end
end

function HelloAction:talkAction(arg)
    if not arg.tag then
        throw("not set argument: \"tag\"")
    end
    if not arg.message then
        throw("not set argument: \"message\"")
    end

    local clientId = self._app:getClientIdByTag(arg.tag)
    if clientId then
        self._app:sendMessageToClient(clientId, arg.message)
    end
end

return HelloAction
