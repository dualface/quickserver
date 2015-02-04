
local UserAction = class("UserAction")

function UserAction:ctor(connect)
    self.connect = connect
end

function UserAction:registerAction(arg)
end

function UserAction:loginAction(arg)
    if not arg.username then
        throw("not set argument: \"username\"")
    end
    local session = self.connect:newSession()
    local uid = ngx.md5(session:getSid())
    session:set("username", arg.username)
    session:set("uid", uid)
    session:save()
    return {sid = session:getSid(), uid = uid}
end

function UserAction:logoutAction(arg)
    if not arg.sid then
        throw("not set argument: \"sid\"")
    end
    local sid = arg.sid
    local session = self.connect:openSession(sid)
    if session then
        local uid = session:get("uid")
        self.connect:closeConnectByTag(uid)
        self.connect:destroySession(sid)
    end
    return {ok = "ok"}
end

return UserAction
