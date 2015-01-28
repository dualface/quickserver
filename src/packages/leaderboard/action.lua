--[[

Copyright (c) 2011-2015 chukong-inc.com

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

local string_format = string.format
local math_trunc = math.trunc

local LeaderboardAction = class("LeaderboardAction")

local function err_(...)
    return {err_msg = string_format(...)}
end

local service = import(".service")

function LeaderboardAction:ctor(app)
    self.leaderboardService = service.new(app)
end

function LeaderboardAction:countAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local ok, err = s:count(data)
    if not ok then
        return err_(err)
    end

    return {count = ok}
end

function LeaderboardAction:addAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local err = nil
    local uid = nil
    uid, err = s:add(data)
    if not uid then
        return err_(err)
    end

    local rank = nil
    rank, err = s:getRank(data)
    if not rank then
        return err_(err)
    end

    local c = nil
    c, err = s:count(data)
    if not c then
        return err_(err)
    end

    return {ok = 1, uid = uid, percent = math_trunc(rank/c*100)}
end

function LeaderboardAction:removeAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local ok, err = s:remove(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1}
end

function LeaderboardAction:scoreAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local score, err = s:score(data)
    if not score then
        return err_(err)
    end

    return {score=score}
end

function LeaderboardAction:getscorerangeAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local res, err = s:getScoreRange(data)
    if not res then
        return err_(err)
    end

    return {scores = res}
end

function LeaderboardAction:getrankAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local rank, err = s:getRank(data)
    if not rank then
        return err_(err)
    end

    local score, err = s:score(data)
    if not score then
        return err_(err)
    end

    return {rank = rank, score = score}
end

function LeaderboardAction:getrevrankAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local revRank, err = s:getRevRank(data)
    if not revRank then
        return err_(err)
    end

    local score, err = s:score(data)
    if not score then
        return err_(err)
    end

    return {rev_rank = revRank, score = score}
end

function LeaderboardAction:getrankrangeAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local res, err = s:getRankRange(data)
    if not res then
        return err_(err)
    end

    return {scores = res}
end

function LeaderboardAction:getrevrankrangeAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local res, err = s:getRevRankrange(data)
    if not res then
        return err_(err)
    end

    return {scores = res}
end

function LeaderboardAction:limitAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local ok, err = s:limit(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1}
end

function LeaderboardAction:revlimitAction(data)
    local s = self.leaderboardService
    if not s then
        return err_("LeaderboardAction is not initialized.")
    end

    local ok, err = s:revLimit(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1}
end

return LeaderboardAction
