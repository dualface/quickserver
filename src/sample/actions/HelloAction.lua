
local HelloAction = class("HelloAction")

function HelloAction:ctor(app)
    self._app = app
end

function HelloAction:sayAction(arg)
    local name = arg.name or "quickserver"
    return string.format("hello, %s", name)
end

function HelloAction:loginAction(arg)
    local secret = arg.secret or "FKO@#23m"
    return self._app:genSession(secret)
end

return HelloAction
