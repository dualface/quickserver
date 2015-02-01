
local UserAction = class("UserAction")

function UserAction:ctor(app)
    self._app = app
end

function UserAction:registerAction(arg)
end

function UserAction:loginAction(arg)
    if not arg.username then
        throw("not set argument: \"username\"")
    end
    local session = self._app:newSession()
    local tag = ngx.md5(session:getSid())
    session:set("username", arg.username)
    session:set("count", 0)
    session:set("tag", tag)
    session:save()
    return {sid = session:getSid(), count = session:get("count"), tag = tag}
end

function UserAction:logoutAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    local session = self._app:openSession(arg.sid)
    if session then
        local tag = session:get("tag")
        self._app:closeConnectByTag(tag)
        self._app:destroySession(arg.sid)
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
