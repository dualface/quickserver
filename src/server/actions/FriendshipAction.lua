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
        self.mysql = app.getMysql(app)
    end

    local storeAction  = require("server.actions.StoreAction")
    self.store = storeAction.new(app)

    self.friends = {}
    self.reply = {}
end

function FriendshipAction:_UpdateFriends(app, source, id, access_token)
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
            
            -- add itself
            local tmpData = {}
            tmpData.app = app
            tmpData.source = source
            tmpData.id = id
            local r = self:ScoreAction(tmpData)
            if r.score then
                frineds[tostring(id)] = res.score
            end
            -- add friends
            for _, v in ipairs(users) do
                tmpData.app = app
                tmpData.source = source 
                tmpData.id = v.id
                r = Self:ScoreAction(tmpData)
                if r.score then
                    friends[tostring(v.id)] = res.score
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

    local friendshipId = data.app .. "_" .. data.source .. "_" .. data.id
    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFriends(data.source, tonumber(data.id), data.access_token)
    end

    local friends = {}
    for k, _ in pairs(self.friends[friendshipId]) do
        if k ~= data.id then 
            table.insert(friends, k)
        end
    end

    self.reply.friends = friends
    
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
    
    local friendshipId = data.app .. "_" .. data.source .. "_" .. data.id
    local tmpData = {}
    tmpData.property = "friendship_id" 
    tmpData.property_value = friendshipId
    echoInfo("property_value = %s", friendshipId)
    local store = self.store
    local res = store:FindobjAction(tmpData)
    if not res.objs then
        return res
    end
    if next(res.objs) == nil then
        self.reply = Err(ERR_FRIENDSHIP_OPERATION_FAILED, "this player id doesn't exist.")
        return self.reply
    end

    local obj = json.decode(res.objs[1].body)
    if data.playlevel and tonumber(data.playlevel) then
        self.reply = {score = obj.scores[data.playlevel]}
    else
        self.reply = {scores = obj.scores}
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
    if data.access_token == nil or data.access_token == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(access_token) is missed")
        return self.reply
    end
    local playlevel = "1"
    if data.playlevel ~= nil and tonumber(data.playlevel) ~= nil then
        playlevel = data.playlevel
    end

    local friendshipId = data.app .. "_" .. data.source .. "_" .. data.id
    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFriends(data.source, tonumber(data.id), data.access_token)
    end
    --self.friends[friendshipId] = {["0000000002"] = {["10"] = "8"}, ["0000000003"] = {["10"] = "8000"}, ["0000000004"] = {["10"] = "88"}}

    local count = tonumber(data.count)
    if count == nil or count > 100 then
        count = 100
    end
    
    local friends = clone(self.friends[friendshipId])
    if count > table.length(friends) then 
        count = table.length(friends)
    end

    local res = {}
    while count ~= 0 do
        local maxScore = -1        
        local maxKey = nil
        echoInfo("count = %s", count)
        for k, v in pairs(friends) do
            local s = tonumber(v[playlevel]) or 0 
            if s > maxScore then
                maxScore = s 
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
    if data.score == nil or data.score == "" then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(access_token) is missed")
        return self.reply
    end
    if data.id == nil or tonumber(data.id) == nil then
        self.reply = Err(ERR_FRIENDSHIP_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local friendshipId = data.app .. "_" .. data.source .. "_" .. data.id
   
    local store = self.store
    assert(store ~= nil, "load StoreAction failed.")
    
    local rawdata = {}
    rawdata.property = "friendship_id"
    rawdata.property_value = friendshipId
    local res = store:FindobjAction(rawdata)

    if res.objs then 
        local obj = json.decode(res.objs[1].body)
        if data.playlevel then 
            if tonumber(data.playlevel) > tonumber(obj.max_play_level) then
                obj.max_play_level = data.playlevel
            end
            obj.scores[data.playlevel] = data.score
        else
            obj.scores["1"] = data.score
        end

        rawdata = {} 
        rawdata.id = res.objs[1].id
        rawdata.rawdata = {}
        table.insert(rawdata.rawdata, {max_play_level = obj.max_play_level})
        table.insert(rawdata.rawdata, {scores = obj.scores})
        res = store:UpdateobjAction(rawdata)
    else 
        local obj = {}
        local scores = {}
        if data.playlevel then
            table.insert(obj, {max_play_level = data.playlevel})
            scores[data.playlevel] = data.score
        else 
            table.insert(obj, {max_play_level = "1"})
            scores["1"] = data.score
        end
        table.insert(obj, {scores = scores})
        table.insert(obj, {friendship_id = friendshipId})

        rawdata = {}
        rawdata.rawdata = obj
        rawdata.indexes = {"friendship_id"} 
        res = store:SaveobjAction(rawdata) 
    end

    if not self.friends[friendshipId] then
        self.friends[friendshipId] = self:_UpdateFriends(data.app, data.source, tonumber(data.id), data.access_token)
    end

    if not res.err_code then
        self.reply = {ok = 1}
    else 
        self.reply = res
    end

    return self.reply
end

return FriendshipAction 
