
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
    local session = self._app:newSession()
    local tag = ngx.md5(session:getSid())
    session:set("username", arg.username)
    session:set("count", 0)
    session:set("tag", tag)
    session:save()
    return {sid = session:getSid(), count = session:get("count"), tag = tag}
end

function HelloAction:logoutAction(arg)
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

function HelloAction:countAction(arg)
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

function HelloAction:sendmessageAction(arg)
    if not arg.tag then
        throw("not set argument: \"tag\"")
    end
    if not arg.message then
        throw("not set argument: \"message\"")
    end
    local connectId = self._app:getConnectIdByTag(arg.tag)
    printWarn("connectId = %s", tostring(connectId))
    if connectId then
        local session = self._app:getSession()
        local message = {
            username = session:get("username"),
            message = arg.message,
            tag = self._app:getConnectTag()
        }
        self._app:sendMessageToConnect(connectId, json.encode(message))
    end
end

return HelloAction
