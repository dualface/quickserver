local strFormat = string.format
local mathTrunc = math.trunc

local LeaderboardAction = class("LeaderboardAction")

local function err_(...)
    return {err_msg = strFormat(...)}
end

local service = import(".service")

function LeaderboardAction:ctor(app)
    self.service = service.new(app)
end

function LeaderboardAction:countAction(data)
    local s = self.service
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
    local s = self.service
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
    
    return {ok = 1, uid = uid, percent = mathTrunc(rank/c*100)}
end

function LeaderboardAction:removeAction(data)
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
    local s = self.service
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
