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
        --self.rankList = app.getRankList(app)
        self.rankList = app.getRedis(app)
    end 

    self.OK = {success=1}
end 

-- zcard 
-- param: ranklist 
function RankListAction:CountAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end 

    if not CheckParams(data, "ranklist") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist missed")
    end 

    local listName = data.ranklist
    local err = nil
    self.OK.count, err = rl:command("zcard", listName)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zcard failed: %s", err)
    end 

    return self.OK
end

-- zadd
-- param: ranklist, key, value 
function RankListAction:AddAction(data)  
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "key", "value") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, key or value missed") 
    end 

    local listName = data.ranklist
    local key = data.key
    local value = data.value
    local err = nil 
    _, err = rl:command("zadd", listName, value, key)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zadd failed: %s", err)
    end 

    return self.OK
end

-- zrem
-- param: ranklist, key
function RankListAction:RemoveAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
    end

    local listName = data.ranklist
    local key = data.key 
    local err = nil 
    _, err = rl:command("zrem", listName, key) 
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zrem failed: %s", err)
    end 

    return self.OK
end

-- zset:dump()
-- param: none
--[[
function RankListAction:DumpAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end

    rl:dump()
    return self.OK 
end
--]]

-- zscore
-- param: ranklist, key
function RankListAction:ScoreAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
    end
    
    local listName = data.ranklist
    local key = data.key
    local err = nil
    self.OK.score, err = rl:command("zscore", listName, key)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zscore failed: %s", err)
    end 

    return self.OK
end

-- zrangebysocre
-- param: ranklist, upper bound, lower bound
function RankListAction:GetScoreRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, upper_bound or lower_bound missed") 
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound)
    local lower = tonumber(data.lower_bound)
    local r, err = rl:command("zrangebyscore", listName, lower, upper)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zrangebyscore failed: %s", err)
    end
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetScoreRangeAction failed: %s", err)
        end
    end 
    self.OK.list = res 
   
    return self.OK
end

-- zrank 
-- param: ranklist, key
function RankListAction:GetRankAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
    end

    local listName = data.ranklist
    local key = data.key
    local err = nil
    self.OK.rank, err = rl:command("zrank", listName, key)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zrank failed: %s", err)
    end
    self.OK.rank = self.OK.rank + 1

    return self.OK
end 

-- zrevrank 
-- param: ranklist, key
function RankListAction:GetRevRankAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "key") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
    end

    local listName = data.ranklist
    local key = data.key
    local err = nil 
    self.OK.rev_rank, err = rl:command("zrevrank", listName, key)
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zrevrank failed: %s", err)
    end
    self.OK.rev_rank = self.OK.rev_rank + 1 

    return self.OK
end 

-- zrange 
-- param: ranklist, upper bound, lower bound 
function RankListAction:GetRankRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, upper_bound or lower_bound missed") 
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound) - 1 
    local lower = tonumber(data.lower_bound) - 1 
    if upper < 0 or lower < 0 then 
        throw(ERR_SERVER_OPERATION_FAILED, "param upper_bound or lower_bound can't be negtive")
    end 

    local r, err = rl:command("zrange", listName, lower, upper)
    if err then  
        throw(ERR_SERVER_REDIS_ERROR, "command zrange failed: %s", err)
    end 
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetRankRangeAction failed: %s", err)
        end
    end 
    self.OK.list = res
    
    return self.OK 
end

-- zrevrange
-- param: ranklist, upper bound, lower bound
function RankListAction:GetRevRankRangeAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "upper_bound", "lower_bound") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param upper_bound or lower_bound missed") 
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound) - 1
    local lower = tonumber(data.lower_bound) - 1 
    if upper < 0 or lower < 0 then 
        throw(ERR_SERVER_OPERATION_FAILED, "param upper_bound or lower_bound can't be negtive")
    end

    local r, err = rl:command("zrevrange", listName, lower, upper)
    if err then  
        throw(ERR_SERVER_REDIS_ERROR, "command zrevrange failed: %s", err)
    end 
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetRevRankRangeAction failed: %s", err)
        end
    end 
    self.OK.list = res 

    return self.OK
end

-- zremrangebyrank, used for reduce some element from tail
-- param: ranklist, count
function RankListAction:LimitAction(data)
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "count") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    local err = nil
    _, err = rl:command("zremrangebyrank", listName, count, -1) 
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zremrangebyrank failed: %s", err)
    end 

    return self.OK 
end

-- zremrangebyrank, used for reduce some element from head, contrary to zset:Limit()
-- param: ranklist, count
function RankListAction:RevLimitAction(data) 
    assert(type(data) ==  "table", "data is NOT a table")

    local rl = self.rankList
    if rl == nil then
        throw(ERR_SERVER_RANKLIST_ERROR, "ranklist object does NOT EXIST")
    end
 
    if not CheckParams(data, "ranklist", "count") then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    local len, err = rl:command("zcard", listName) 
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zcard in RevLimitAction failed: %s", err)
    end 
    _, err = rl:command("zremrangebyrank", listName, 0, len-count-1) 
    if err then 
        throw(ERR_SERVER_REDIS_ERROR, "command zremrangebyrank in RevLimitAction failed: %s", err)
    end 

    return self.OK
end

return RankListAction
