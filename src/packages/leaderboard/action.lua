local LeaderboardAction = class("LeaderboardAction")

local function _err(...)
    return {err_msg = string.format(...)}
end

function LeaderboardAction:ctor(app, cls)
    local sevice = import(".service").new(app) 

    if cls == nil then 
       echoError("Please specify a class to carry pakcage actions,  or you can import pakcage service only.") 
       return 
    end

    -- export action method
    local find = string.find
    for k, v in pairs(self) do 
        if type(v) == "function" and find(k, "Action$") then
            cls[k] = v 
        end
    end
    cls.service = service
end

function LeaderboardAction:CountAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local ok, err = s:Count(data)
    if not ok then 
        return _err(err)
    end

    return {count = ok}
end

function LeaderboardAction:AddAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local err = nil
    local uid = nil
    uid, err = s:Add(data)
    if not uid then
        return _err(err)
    end

    local rank = nil 
    rank, err = s:Getrank(data)
    if not rank then
        return _err(err)
    end

    local c = nil
    c, err = s:Count(data)
    if not c then
        return _err(err)
    end
    
    return {ok = 1, uid = uid, percent = math.trunc(rank/c)}
end

function LeaderboardAction:RemoveAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local ok, err = s:Remove(data)
    if not ok then
        return _err(err)        
    end

    return {ok = 1} 
end

function LeaderboardAction:ScoreAction(data) 
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end
    
    local score, err = s:Score(data)
    if not score then
        return _err(err)
    end

    return {score=score} 
end

function LeaderboardAction:GetscorerangeAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local res, err = s:Getscorerange(data)
    if not res then
        return _err(err)
    end

    return {scores = res} 
end

function LeaderboardAction:GetrankAction(data) 
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local rank, err = s:Getrank(data)
    if not rank then
        return _err(err)
    end

    local score, err = s:Score(data)
    if not score then
        return _err(err)
    end

    return {rank = rank, score = score} 
end 

function LeaderboardAction:GetrevrankAction(data) 
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local revRank, err = s:Getrevrank(data)
    if not revRank then
        return _err(err)
    end

    local score, err = s:Score(data)
    if not score then
        return _err(err)
    end

    return {rev_rank = revRank, score = score} 
end 

function LeaderboardAction:GetrankrangeAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local res, err = s:Getrankrange(data) 
    if not res then
        return _err(err)
    end
    
    return {scores = res} 
end

function LeaderboardAction:GetrevrankrangeAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local res, err = s:Getrevrankrange(data)
    if not res then
        return _err(err)
    end

    return {scores = res} 
end

function LeaderboardAction:LimitAction(data)
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local ok, err = s:Limit(data)
    if not ok then
        return _err(err)
    end

    return {ok = 1} 
end

function LeaderboardAction:RevlimitAction(data) 
    local s = self.service
    if not s then
        return _err("LeaderboardAction is not initialized.")
    end

    local ok, err = s:Revlimit(data)
    if not ok then
        return _err(err)
    end

    return {ok = 1} 
end

return LeaderboardAction
