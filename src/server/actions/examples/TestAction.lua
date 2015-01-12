local LeaderboardAction = cc.load("leaderboard").action

local TestAction = class("TestAction", LeaderboardAction) 

function TestAction:ctor(app)
    self.super:ctor(app)
end 

return TestAction
