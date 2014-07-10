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

local ERR_RANKLIST_INVALID_PARAM = 1000
local ERR_RANKLIST_OPERATION_FAILED = 1100

local function Err(errCode, errMsg, ...) 
   local msg = string.format(errMsg, ...)

   return {err_code=errCode, err_msg=msg} 
end

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

    self.reply = {}
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist missed")
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "param(ranklist) missed")
        return self.reply
    end 

    local listName = data.ranklist
    local err = nil
    self.reply.count, err = rl:command("zcard", listName)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zcard failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zcard failed: %s", err)
        return self.reply
    end 

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, key or value missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist, key or value) missed")
        return self.reply
    end 

    local listName = data.ranklist
    local key = data.key
    local value = data.value
    local err = nil 
    _, err = rl:command("zadd", listName, value, key)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zadd failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zadd failed: %s", err)
        return self.reply
    end 

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or key) missed")
        return self.reply
    end

    local listName = data.ranklist
    local key = data.key 
    local err = nil 
    _, err = rl:command("zrem", listName, key) 
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zrem failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrem failed: %s", err)
        return self.reply
    end 

    return self.reply
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
    return self.reply 
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or key) missed")
        return self.reply
    end
    
    local listName = data.ranklist
    local key = data.key
    local err = nil
    self.reply.score, err = rl:command("zscore", listName, key)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zscore failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zscore failed: %s", err)
        return self.reply
    end 

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, upper_bound or lower_bound missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist, lower_bound or upper_bound) missed")
        return self.reply
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound)
    local lower = tonumber(data.lower_bound)
    local r, err = rl:command("zrangebyscore", listName, lower, upper)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zrangebyscore failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrangebysocre failed :%s", err)
        return self.reply
    end
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            --throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetScoreRangeAction failed: %s", err)
            self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zscore in GetScoreRangeAction failed :%s", err)
            return self.reply
        end
    end 
    self.reply.list = res 
   
    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or key) missed")
        return self.reply
    end

    local listName = data.ranklist
    local key = data.key
    local err = nil
    self.reply.rank, err = rl:command("zrank", listName, key)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zrank failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrank failed :%s", err)
        return self.reply
    end
    if self.reply.rank == nil then 
        return self.reply
    end
    self.reply.rank = self.reply.rank + 1

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist or key missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or key) missed")
        return self.reply
    end

    local listName = data.ranklist
    local key = data.key
    local err = nil 
    self.reply.rev_rank, err = rl:command("zrevrank", listName, key)
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zrevrank failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrerank failed :%s", err)
        return self.reply
    end
    if self.reply.rank == nil then 
        return self.reply
    end
    self.reply.rev_rank = self.reply.rev_rank + 1 

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param ranklist, upper_bound or lower_bound missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist, upper_bound or lower_bound) missed")
        return self.reply
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound) - 1 
    local lower = tonumber(data.lower_bound) - 1 
    if upper < 0 or lower < 0 then 
        --throw(ERR_SERVER_OPERATION_FAILED, "param upper_bound or lower_bound can't be negtive")
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(upper_bound or lower_bound) can't be negtive")
        return self.reply
    end 

    local r, err = rl:command("zrange", listName, lower, upper)
    if err then  
        --throw(ERR_SERVER_REDIS_ERROR, "command zrange failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrange failed :%s", err)
        return self.reply
    end 
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            --throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetRankRangeAction failed: %s", err)
            self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zsocre in GetRankRangeAction failed :%s", err)
            return self.reply
        end
    end 
    self.reply.list = res
    
    return self.reply 
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param upper_bound or lower_bound missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist, upper_bound or lower_bound) missed")
        return self.reply
    end

    local listName = data.ranklist
    local upper = tonumber(data.upper_bound) - 1
    local lower = tonumber(data.lower_bound) - 1 
    if upper < 0 or lower < 0 then 
        --throw(ERR_SERVER_OPERATION_FAILED, "param upper_bound or lower_bound can't be negtive")
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(upper_bound or lower_bound) can't be negtive")
        return self.reply
    end

    local r, err = rl:command("zrevrange", listName, lower, upper)
    if err then  
        --throw(ERR_SERVER_REDIS_ERROR, "command zrevrange failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zrevrange failed :%s", err)
        return self.reply
    end 
    local res = {} 
    for _, v in pairs(r) do 
        res[v], err = rl:command("zscore", listName, v) 
        if err then 
            --throw(ERR_SERVER_REDIS_ERROR, "command zscore in GetRevRankRangeAction failed: %s", err)
            self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zscore in GetRevRankRangeAction failed :%s", err)
            return self.reply
        end
    end 
    self.reply.list = res 

    return self.reply
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or count) missed")
        return self.reply
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    local err = nil
    _, err = rl:command("zremrangebyrank", listName, count, -1) 
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zremrangebyrank failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zremrangebyrank failed :%s", err)
        return self.reply
    end 

    return self.reply 
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
        --throw(ERR_SERVER_INVALID_PARAMETERS, "param count missed") 
        self.reply = Err(ERR_RANKLIST_INVALID_PARAM, "params(ranklist or count) missed")
        return self.reply
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    local len, err = rl:command("zcard", listName) 
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zcard in RevLimitAction failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zcard in RevLimitAction failed :%s", err)
        return self.reply
    end 
    _, err = rl:command("zremrangebyrank", listName, 0, len-count-1) 
    if err then 
        --throw(ERR_SERVER_REDIS_ERROR, "command zremrangebyrank in RevLimitAction failed: %s", err)
        self.reply = Err(ERR_RANKLIST_OPERATION_FAILED, "command zremrangebyrank failed :%s", err)
        return self.reply
    end 

    return self.reply
end

return RankListAction
