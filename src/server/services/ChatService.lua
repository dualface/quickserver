
--[[--

聊天服务

]]

local ChatService = class("ChatService")

function ChatService:ctor(app)
    self.app   = app
    self.redis = app:getRedis()
end

-- 读取聊天
function ChatService:load(uid, channel)
    local res, err = self.redis:command("hmget", uid, "allianceId", "chatChannel")
    if err then
        throw(ERR_SERVER_INVALID_PARAMETERS, err)
    end

    local allianceId, chatChannel = res[1], toint(res[2])

    local channelId, channelUserId, total, rows = WORLD_CHAT_KEY, WORLD_CHAT_USER_KEY, MAX_WORLD_CHAT_TOTAL, WORLD_CHAT_ROWS
    if allianceId ~= "" and channel == CHAT_CHANNEL_ALLIANCE then
        channelId, channelUserId, total, rows = string.format(ALLIANCE_CHAT_KEY, allianceId),
            string.format(ALLIANCE_CHAT_USER_KEY, allianceId), MAX_WORLD_CHAT_TOTAL, WORLD_CHAT_ROWS
    end

    local res, err = self.redis:command("lrange", channelId, 0, rows - 1)

    if err then
        throw(ERR_SERVER_INVALID_PARAMETERS, err)
    end

    if chatChannel ~= channel then
        local transaction = self.redis:newTransaction()
        transaction:watch(channelUserId)
        transaction:command("sadd", channelUserId, uid)
        if chatChannel == CHAT_CHANNEL_WORLD then
            transaction:command("srem", WORLD_CHAT_USER_KEY, uid)
        elseif allianceId ~= "" and chatChannel == CHAT_CHANNEL_ALLIANCE then
            transaction:command("srem", string.format(ALLIANCE_CHAT_USER_KEY, allianceId), uid)
        end
        transaction:command("hmset", uid, {chatChannel = channel})

        local ok, err = transaction:commit()
        if err then
            throw(ERR_SERVER_INVALID_PARAMETERS, err)
        end
    end

    return res

end

-- 发送聊天记录
function ChatService:send(uid, message)
    local res, err = self.redis:command("hmget", uid, "allianceId", "chatChannel", "nickname", "avatar")

    if err then
        throw(ERR_SERVER_INVALID_PARAMETERS, err)
    end

    local allianceId, chatChannel, nickname, avatar = res[1], toint(res[2]), res[3], res[4]

    local channelId, channelUserId, total, rows = WORLD_CHAT_KEY, WORLD_CHAT_USER_KEY, MAX_WORLD_CHAT_TOTAL, WORLD_CHAT_ROWS
    if allianceId ~= "" and chatChannel == CHAT_CHANNEL_ALLIANCE then
        channelId, channelUserId, total, rows = string.format(ALLIANCE_CHAT_KEY, allianceId),
            string.format(ALLIANCE_CHAT_USER_KEY, allianceId), MAX_WORLD_CHAT_TOTAL, WORLD_CHAT_ROWS
    end

    local time = os.time()
    local msg = {
        u = uid,
        t = time,
        n = nickname,
        a = avatar,
        m = message
    }

    return channelUserId, channelId, msg, total
end

return ChatService