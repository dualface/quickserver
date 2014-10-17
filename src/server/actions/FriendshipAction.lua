local ERR_FRIENDSHIP_INVALID_PARAM = 5000
local ERR_FRIENDSHIP_OPERATION_FAILED = 5100


local FriendshipAction = class("FriendshipAction", cc.server.ActionBase)

local function Err(errCode, errMsg, ...)
    local msg = string.format(errMsg, ...)

    return {err_code = errCode, err_msg=msg}
end

function FriendshipAction:ctor(app)
    self.super:ctor(app)
    
    if app then 
        self.redis = app.getRedis(app)
        self.mysql = app.getMysql(app)
    end

    local storeAction  = require("StoreAction")
    self.store = storeAction.new(app)

    self.friends = {}
    self.reply = {}
end

function FriendshipAction:_UpdateFrineds(app, source, id, access_token)

    local httpClient = cc.server.http:new()

    local bodyStr = nil 
    local reqBody = {}
    local ok = nil
    local code = nil 
    local status = nil
    local err = nil

    local friends = {}
    if source == "weibo" then 
        local cursor = 0
        while true do
            local b = {
                access_token = access_token,
                uid = id,
                count = 200,
                cursor = cursor,
                trim_status = 1,
            }
            ok, code, _, status, bodyStr = httpClient:request{
                url = [[https://api.weibo.com/2/friendships/friends.json]],
                method = "GET",
                headers = {["Content-Type"] = [[application/json]]},
                body = json.encode(b)
            }

            local res = json.decode(bodyStr)
            local users = res.users 
            if res.next_cursor == 0 then
                break
            end
            
            for _, v in ipairs(users) do
                local tmpData = {}
                tmpData.app = app
                tmpData.source = source 
                tmpData.id = tonumber(v.id)
                local res = Self:ScoreAction(tmpData)
                if res.score then
                    friends[tonumber(v.id)] = res.score
                end
            end
            cursor = res.next_cursor
        end
    end

    return friends
end

function FriendshipAction:FriendsAction(data)
    assert(type(data) == "table", "data is NOT a table") 

    if data.app == nil or data.app == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(app) is missed")
        return self.reply
    end
    if data.source == nil or data.source == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(source) is missed")
        return self.reply
    end
    if data.access_token == nil or data.access_token == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(access_token) is missed")
        return self.reply
    end
    if data.id == nil or tonumber(data.id) == nil then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local friendshipId = data.app .. "_" .. data.source .. "_" .. tostring(data.id)
    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFrineds(data.source, tonumber(data.id), data.access_token)
    end

    self.reply.friends = self.friends[friendshipId]
    
    return self.reply
end

function FriendshipAction:ScoreAction(data)
    assert(type(data) == "table", "data is NOT a table")
    
    if data.app == nil or data.app == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(app) is missed")
        return self.reply
    end
    if data.source == nil or data.source == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(source) is missed")
        return self.reply
    end
    if data.id == nil or tonumber(data.id) == nil then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end
    
    local friendshipId = data.app .. "_" .. data.source .. "_" .. tostring(data.id)
    local tmpData = {}
    tmpData.property = "friendship_id" 
    tmpData.property_value = friendshipId
    local res = store:FindobjAction(tmpdata)
    if not res.objs then
        return res
    end
    if next(res.objs) == nil then
        self.reply = Err(ERR_FRIENDSHIP_OPERATION_FAILED, "this player id doesn't exist.")
        return self.reply
    end

    local obj = json.decode(res.objs[1].body)
    local playlevel = tonumber(data.playlevel)
    if playlevel == nil then 
        self.reply = {score = obj.scores[1]}
    else
        self.reply = {score = obj.scores[playlevel]}
    end

    return self.reply
end

function FriendshipAction:RanklistAction(data)
    assert(type(data) == "table", "data is NOT a table")

    if data.app == nil or data.app == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(app) is missed")
        return self.reply
    end
    if data.source == nil or data.source == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(source) is missed")
        return self.reply
    end
    if data.id == nil or tonumber(data.id) == nil then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local friendshipId = data.app .. "_" .. data.source .. "_" .. tostring(data.id)
    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFrineds(data.source, tonumber(data.id), data.access_token)
    end

    local count = tonumber(data.count)
    if count == nil then
        count = 100
    end

    local friends = clone(self.friends)
    local res = {}

    while count ~= 0 do
        local maxScore = -1        
        local maxKey = nil

        for k, v in pairs(friends) do
            if v > maxScore then
                maxScore = v
                maxKey = k
            end
        end
        table.insert(res, {id = maxKey, score = maxScore})
        friends[maxKey] = nil
        count = count - 1
    end

    self.reply.res = res

    return self.reply
end

function FriendshipAction:UpdateplayerAction(data)
    assert(type(data) == "table", "data is NOT a table") 

    local mysql = self.mysql 
    if mysql == nil then
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    if data.app == nil or data.app == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(app) is missed")
        return self.reply
    end
    if data.source == nil or data.source == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(source) is missed")
        return self.reply
    end
    if data.access_token == nil or data.access_token == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(access_token) is missed")
        return self.reply
    end
    if data.id == nil or tonumber(data.id) == nil then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local friendshipId = data.app .. "_" .. data.source .. "_" .. tostring(data.id)
   
    local store = self.store
    assert(store ~= nil, "load StoreAction failed.")
    
    local rawdata = {}
    rawdata.property = "friendship_id"
    rawdata.property_value = friendshipId
    local res = store:FindobjAction(rawdata)

    if res.objs then 
        local obj = json.decode(res.objs[1].body)
        if data.playlevel then 
            if data.playlevel > obj.max_play_level then
                obj.max_play_level = data.playlevel
            end
            obj.scores[data.playlevel] = data.score
        else
            obj.scores[1] = data.score
        end

        rawdata = {} 
        rawdata.id = res.id
        raswdata.rawdata = obj
        res = store:UpdateobjAction(rawdata)
    else 
        local obj = {}
        obj.max_play_level = data.playlevel
        obj.scores[data.playlevel] = data.score
        obj.friendship_id = friendshipId

        rawdata = {}
        rawdata.rawdata = obj
        rawdata.indexes = {"friendship_id"} 
        res = store:SaveobjAction(rawdata) 
    end

    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFrineds(data.app, data.source, tonumber(data.id), data.access_token)
    end

    if not res.err_code then
        self.reply = {ok = 1}
    else 
        self.reply = res
    end

    return self.reply
end

return FriendshipAction 
