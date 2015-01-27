--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local type = type
local next = next
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local table_length = table.nums
local table_insert = table.insert
local string_format = string.format

local LeaderboardService = class("LeaderboardService")

function LeaderboardService:ctor(app)
    local config = nil
    if app then
        config = app.config.redis
    end
    self.redis = cc.load("redis").service.new(config)
    self.redis:connect()
end

function LeaderboardService:endService()
    self.redis:close()
end

local function checkParams_(data, ...)
    local arg = {...}

    if table_length(arg) == 0 then
        return true
    end

    for _, name in pairs(arg) do
        if data[name] == nil or data[name] == "" then
           return false
        end
    end

    return true
end

function LeaderboardService:count(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist") then
        return nil, "'ranklist' is missed in param table."
    end
    local listName = data.ranklist

    return rds:command("zcard", listName)
end

function LeaderboardService:generateUID_(nickname)
    local rds = self.redis

    if rds:command("hget", "__ranklist_uid", nickname.."+") ~= "1" then
        rds:command("hset","__ranklist_uid", nickname.."+", 1)
        return nickname .. "+"
    end

    local i = 1
    local uid = nickname .. "+" .. tostring(i)
    while rds:command("hget", "__ranklist_uid", uid) == "1" do
        i = i + 1
        uid = nickname .. "+" .. tostring(i)
    end
    rds:command("hset", "__ranklist_uid", uid, 1)

    return uid
end

-- zadd
-- param: ranklist, value
function LeaderboardService:add(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if checkParams_(data, "ranklist", "nickname", "value") then
        data.uid = self:generateUID_(data.nickname)
    elseif not checkParams_(data, "uid", "ranklist", "value") then
        return nil, "'uid', 'ranklist' or 'value' is missed in param table."
    end

    if rds:command("hget", "__ranklist_uid", data.uid) ~= "1" then
        return nil, string_format("'uid(%s)' doesn't exist.", data.uid)
    end

    local listName = data.ranklist
    local key = data.uid
    local value = tonumber(data.value)
    if type(value) ~= "number" then
        return nil, string_format("'value(%s)' is not a number.", tostring(data.value))
    end
    local ok, err = rds:command("zadd", listName, value, key)
    if not ok then
       return nil, err
    end

    return key, nil
end

-- zrem
-- param: ranklist
function LeaderboardService:remove(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "uid", "ranklist") then
        return nil, "'uid' or 'ranklist' is missed in param table."
    end

    local listName = data.ranklist
    local key = data.uid
    local err = nil
    ok, err = rds:command("zrem", listName, key)
    if not ok then
        return nil, err
    end
    rds:command("hdel", "__ranklist_uid", key)

    return true, nil
end

-- zscore
-- param: ranklist
function LeaderboardService:score(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "uid", "ranklist") then
        return nil, "'uid' or 'ranklist' is missed in param table."
    end

    local listName = data.ranklist
    local key = data.uid
    local score, err = rds:command("zscore", listName, key)
    if not score then
        return nil, err
    end

    if tostring(score) == "userdata: NULL" then
        return "null", nil
    end

    return score, nil
end

-- zrangebysocre
-- param: ranklist, min, max
function LeaderboardService:getScoreRange(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist", "min", "max") then
        return nil, "'ranklist', 'min' or 'max' is missed in param table."
    end

    local listName = data.ranklist
    local upper = tonumber(data.max)
    local lower = tonumber(data.min)
    if not upper or not lower then
        return nil, string_format("'max(%s)' or 'min(%s)' is not a number.", tostring(data.max), tostring(data.min))
    end

    local r, err = rds:command("zrangebyscore", listName, lower, upper)
    if not r then
        return nil, err
    end
    local res = {}
    for _, v in pairs(r) do
        local s = nil
        s, err = rds:command("zscore", listName, v)
        if not s then
            return nil, err
        end
        table_insert(res, {uid = v, score = s})
    end
    if next(res) == nil then
        return "null", nil
    end

    return res, nil
end

-- zrank
-- param: ranklist
function LeaderboardService:getRank(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "uid", "ranklist") then
        return nil, "'uid' or 'ranklist' is missed in param table."
    end

    local listName = data.ranklist
    local key = data.uid
    local rank, err = rds:command("zrank", listName, key)
    if not rank then
        return nil, err
    end
    if tostring(rank) == "userdata: NULL" then
        return "null", nil
    end

    return rank+1, nil
end

-- zrevrank
-- param: ranklist
function LeaderboardService:getRevRank(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "uid", "ranklist") then
        return nil, "'uid' or 'ranklist' is missed in param table."
    end

    local listName = data.ranklist
    local key = data.uid
    local revRank, err = rds:command("zrevrank", listName, key)
    if not revRank then
        return nil, err
    end
    if tostring(revRank) == "userdata: NULL" then
        return "null", nil
    end

    return revRank+1, nil
end

-- zrange
-- param: ranklist, offset, count
function LeaderboardService:getRankRange(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist", "offset", "count") then
        return nil, "'ranklist', 'offset' or 'count' is missed in param table."
    end

    local listName = data.ranklist
    local offset = tonumber(data.offset)
    local count = tonumber(data.count)
    if not offset or not count then
        return nil, string_format("'offset(%s)' or 'count(%s)' is not a number.", tostring(data.offset), tostring(data.count))
    end
    offset = offset - 1

    if offset < 0 or count <= 0 then
        return nil, "'offset' or 'count' can't be negtive or zero."
    end

    local r, err = rds:command("zrange", listName, offset, offset+count-1)
    if not r then
        return nil, err
    end

    local res = {}
    for _, v in pairs(r) do
        local s = nil
        s, err = rds:command("zscore", listName, v)
        if not s then
            return nil, err
        end
        table_insert(res, {uid = v, score = s})
    end
    if next(res) == nil then
        return "null", nil
    end

    return res, nil
end

-- zrevrange
-- param: ranklist, offset, count
function LeaderboardService:getRevRankRange(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist", "offset", "count") then
        return nil, "'ranklist', 'offset' or 'count' is missed in param table."
    end

    local listName = data.ranklist
    local offset = tonumber(data.offset)
    local count = tonumber(data.count)
    if not offset or not count then
        return nil, string_format("'offset(%s)' or 'count(%s)' is not a number.", tostring(data.offset), tostring(data.count))
    end
    offset = offset - 1

    if offset < 0 or count <= 0 then
        return nil, "'offset' or 'count' can't be negtive or zero."
    end

    local r, err = rds:command("zrevrange", listName, offset, offset+count-1)
    if not r then
        return nil, err
    end

    local res = {}
    for _, v in pairs(r) do
        local s = nil
        s, err = rds:command("zscore", listName, v)
        if not s then
            return nil, err
        end
        table_insert(res, {uid = v, score = s})
    end
    if next(res) == nil then
        return "null", nil
    end

    return res, nil
end

-- zremrangebyrank, used for reduce some element from tail
-- param: ranklist, count
function LeaderboardService:limit(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist", "count") then
        return nil, "'ranklist' or 'count' is missed in param table."
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    if not count then
        return nil, string_format("'count(%s) is not a number.", tostring(data.count))
    end

    if count < 0 then
        return nil, "'count' can't be negtive."
    end

    local ok, err = rds:command("zremrangebyrank", listName, count, -1)
    if not ok then
        return nil, err
    end

    return true, nil
end

-- zremrangebyrank, used for reduce some element from head, contrary to zset:Limit()
-- param: ranklist, count
function LeaderboardService:revLimit(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "ranklist", "count") then
        return nil, "'ranklist' or 'count' is missed in param table."
    end

    local listName = data.ranklist
    local count = tonumber(data.count)
    if not count then
        return nil, string_format("'count(%s) is not a number.", tostring(data.count))
    end

    if count < 0 then
        return nil, "'count' can't be negtive."
    end

    local len, err = rds:command("zcard", listName)
    if not len then
        return nil, err
    end

    if len > count then
        local ok = nil
        ok, err = rds:command("zremrangebyrank", listName, 0, len-count-1)
        if not ok then
            return nil, err
        end
    end

    return true, nil
end

return LeaderboardService
