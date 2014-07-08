--[[
--
--REQ
    {
        "acton" : "RankList.add", 
        "key": "hqy"
        "value": "92"
        ]
    }
--
--]]

local function CheckParams(data, ...)
    local arg = {...} 

    if table.length(arg) == 0 then 
        return true
    end 
    
    for _, name in pairs(arg) do 
        if data[name] == nil then 
           return false 
        end 
    end 

    return true 
end 

local RankListAction = class("RankListAction", cc.server.ActionBase) 

function RankListAction:ctor(app)
    self.super:ctor(app)

    if app then 
        self.rankList = app.getRankList(app)
    end 

    self.OK = {success=1}
end 

-- zset:count() 
-- param: none
function RankListAction:CountAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end 

    self.OK.count = self.rankList:count()
    return self.OK
end

-- zset:add()
-- param: key, value 
function RankListAction:AddAction(data)  
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "key", "value") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param key or value missed") 
    end 

    local key = data.key
    local value = data.value
    rl:add(value, key)

    return self.OK
end

-- zset:rem()
-- param: key
function RankListAction:RemoveAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param key missed") 
    end

    local key = data.key 
    rl:rem(key)

    return self.OK
end

-- zset:dump()
-- param: none
function RankListAction:DumpAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end

    rl:dump()
    return self.OK 
end

-- zset:score()
-- param: key
function RankListAction:ScoreAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param key missed") 
    end
    
    local key = data.key
    self.OK.score = rl:score(key)

    return self.OK
end

-- zset:range_by_socre()
-- param: upper bound, lower bound
function RankListAction:GetScoreRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param upper_bound or lower_bound missed") 
    end

    local upper = tonumber(data.upper_bound)
    local lower = tonumber(data.lower_bound)
    local r = rl:range_by_score(lower, upper)
    local res = {} 
    for _, v in pairs(r) do 
        res[v] = rl:score(v)
    end 
    self.OK.list = res 
   
    return self.OK
end

-- zset:rank() 
-- param: key
function RankListAction:GetRankAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param key missed") 
    end

    local key = data.key
    self.OK.rank = rl:rank(key)

    return self.OK
end 

-- zset:rev_rank()
-- param: key
function RankListAction:GetRevRankAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param key missed") 
    end

    local key = data.key
    self.OK.rev_rank = rl:rev_rank(key)

    return self.OK
end 

-- zset:range() 
-- param: upper bound, lower bound 
function RankListAction:GetRankRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param upper_bound or lower_bound missed") 
    end

    local upper = tonumber(data.upper_bound)
    local lower = tonumber(data.lower_bound)
    local r = rl:range(lower, upper)
    local res = {} 
    for _, v in pairs(r) do 
        res[v] = rl:score(v) 
    end 
    self.OK.list = res 
    
    return self.OK 
end

-- zset:rev_range()
-- param: upper bound, lower bound
function RankListAction:GetRevRankRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param upper_bound or lower_bound missed") 
    end

    local lower = tonumber(data.lower_bound)
    local upper = tonumber(data.upper_bound)
    local r = rl:rev_range(lower, upper) 
    local res = {} 
    for _, v in pairs(r) do 
        res[v] = rl:score(v)
    end 
    self.OK.list = res 

    return self.OK
end

-- zset:Limit(), used for reduce some element from tail
-- param: count
function RankListAction:LimitAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "count") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
    end

    local count = tonumber(data.count)
    rl:limit(count) 

    return self.OK 
end

-- zset:RevLimit(), used for reduce some element from head, contrary to zset:Limit()
-- param: count
function RankListAction:RevLimitAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "count") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
    end

    local count = tonumber(data.count)
    rl:rev_limit(count) 

    return self.OK
end

return RankListAction
