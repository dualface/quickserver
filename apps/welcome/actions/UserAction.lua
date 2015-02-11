
local UserAction = class("UserAction")

function UserAction:ctor(app)
    self._app = app
end

function UserAction:loginAction(arg)
    if not arg.username then
        throw("not set argument: \"username\"")
    end
    local session = self._app:newSession()
    session:set("username", arg.username)
    session:set("count", 0)
    session:save()
    return {sid = session:getSid(), count = session:get("count")}
end

function UserAction:logoutAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    local session = self._app:openSession(arg.sid)
    if session then
        local connectId = session:getConnectId()
        self._app:closeConnect(connectId)
        self._app:destroySession()
    end
    return {ok = "ok"}
end

function UserAction:countAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    local session = self._app:openSession(arg.sid)
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

return UserAction
