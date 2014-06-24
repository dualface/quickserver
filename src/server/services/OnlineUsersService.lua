
local OnlineUsersService = class("OnlineUsersService")

function OnlineUsersService:ctor(app)
    self.app = app
    self.redis = app:getRedis()
end

-- 检查指定 uid 的玩家是否在线
function OnlineUsersService:isUserOnline(uid)
    local ok = self.redis:command("SISMEMBER", ONLINE_USERS_SET_NAME, uid)
    return ok == 1
end

-- 设置指定玩家的在线状态
function OnlineUsersService:setUserOnline(uid)
    self.redis:command("SADD", ONLINE_USERS_SET_NAME, uid)
end

-- 踢走指定的玩家
function OnlineUsersService:kickUser(uid)
    -- 向指定频道发送 kick 消息
    self.app.messageService:sendMessageToUser(uid, string.format("keep %d", self.app.sessionId))
    -- 从在线用户列表中清除 uid
    self.redis:command("SREM", ONLINE_USERS_SET_NAME, uid)
end

return OnlineUsersService
