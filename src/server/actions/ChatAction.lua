local ERR_CHAT_INVALID_PARAM  = 4000
local ERR_CHAT_OPERATION_FAILED = 4100

local ChatAction = class("ChatAction", cc.server.ActionBase)

local function Err(errCode, errMsg, ...)
    local msg = string.format(errMsg, ...)

    return {err_code = errCode, err_msg=msg}
end

function ChatAction:ctor(app)
    self.super:ctor(app)

    if app then 
        if app.requestType == "websockets" then
            self.isWebSocket = true
            self.websocketInfo = app.websocketInfo

            -- redis
            self.redis = app.getRedis(app)            

            -- for gettime function
            self.socket = require("socket") 

            -- get the configs about chating
            self.chatRecNum = app.config.chat.recordNum
            self.channelNum = app.config.chat.channelNum
            self.peoplePerCh = app.config.chat.peoplePerCh
        else 
            self.reply = Err(ERR_CHAT_OPERATION_FAILED, "ChatAction: this action can't be access by http")
            return self.reply
        end
    end

    self.reply = {}
end

function ChatAction:_RemoveChatRecords(count)
    local redis = self.redis
    local res, err = redis:command("zrange", "__chat_time", 0, count+1, "withscores")
    if not res then
        echoError("redis command zrange failed: %s", err)
        return nil, err 
    end

    for i = 2, #res, 2 do
       redis:command("hdel", "__chat_channel", res[i]) 
       redis:command("hdel", "__chat_content", res[i])
    end

    return true, nil
end

function ChatAction:BroadcastAction(data)
    if not self.isWebSocket then 
        self.reply = Err(ERR_USER_OPERATION_FAILED, "operation Chat.Broadcast failed: this operation is allowed to access only though WebSocket.")
        return self.reply
    end

    -- assign channel first time
    if self.websocketInfo.channel == nil then
        local chs = ngx.shared.CHANNELS
        local key
        local channelNum = self.channelNum
        local peoplePerCh = self.peoplePerCh
        for i = 1, channelNum do
            key = "ch" .. tostring(i)
            if chs:get(key) == nil then 
                chs:set(key, 1)
                break
            end
            if chs:get(key) < peoplePerCh then
                chs:incr(key, 1)
                break;
            end
        end
        self.websocketInfo.channel = key
    end
    
    local redis = self.redis
    local now = self.socket.gettime()
    if data.content ~= nil and data.content ~= "" then
        -- store the timestamp to sorted list 
        local content = data.content
        local user = data.user
        if data.user == nil or data.user == "" then
            user = "anonymous"
        end
        local count = redis:command("zcard", "__chat_time") 
        if count and count > self.chatRecNum then  
            local ok, err = self:_RemoveChatRecords(count - self.chatRecNum)
            if not ok then 
                self.reply = Err(ERR_CHAT_OPERATION_FAILED, "operation Chat.Broadcast failed: %s", err)
                return self.reply
            end
        end
        local ok, err = redis:command("zadd", "__chat_time", now*10000, ngx.encode_base64(tostring(now))) 
        if not ok then
            echoError("redis command zadd failed: %s", err)
            self.reply = Err(ERR_CHAT_OPERATION_FAILED, "operation Chat.Broadcast failed: store the timestamp of chating error.")
            return self.reply
        end

        -- stroe channel info to hash
        ok, err = redis:command("hset", "__chat_channel", now*10000, self.websocketInfo.channel)
        if not ok then
            echoError("redis command hset failed: %s", err)
            self.reply = Err(ERR_CHAT_OPERATION_FAILED, "operation Chat.Broadcast failed: store the channel info error.")
            return self.reply
        end

        -- stroe chat content to hash
        ok, err = redis:command("hset", "__chat_content", now*10000, user .. ":" .. content)
        if not ok then
            echoError("redis command hset failed: %s", err)
            self.reply = Err(ERR_CHAT_OPERATION_FAILED, "operation Chat.Broadcast failed: store the chat content error.")
            return self.reply
        end
    end

    -- push previous chat contents
    local lastTime = now - 120  -- could give a param instead of "120"  
    local res, err = redis:command("zrangebyscore", "__chat_time", "("..tostring(lastTime*10000), now*10000, "withscores")
    if not res then 
        echoError("redis command zrangebyscore failed: %s", err)
        self.reply = Err(ERR_CHAT_OPERATION_FAILED, "operation Chat.Broadcast failed: send previous chat contents error.")
        return self.reply
    end
    self.reply.contents = {}
    if tostring(res) == "userdata: NULL" then 
        return self.reply
    end

    local currentCh = self.websocketInfo.channel 
    for i = 2, #res, 2 do
        local ch, err = redis:command("hget", "__chat_channel", res[i])
        if ch and tostring(ch) ~= "userdata: NULL" and ch == currentCh then
            local content, err = redis:command("hget", "__chat_content", res[i])
            if content and tostring(content) ~= "userdata: NULL" then 
                table.insert(self.reply.contents, content)
            end
        end
    end

    return self.reply
end

return ChatAction
