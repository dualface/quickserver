local LeaderboardAction = class("LeaderboardAction") 

function LeaderboardAction:ctor(app)
    self.leaderboard = cc.load("leaderboard").action.new(app, self)
end 

return LeaderboardAction
