local leaderboardAction = cc.load("leaderboard").action
local storageActon = cc.load("objectstorage").action

local TestAction = class("TestAction", storageActon, leaderboardAction)

function TestAction:ctor(app)
    for _, s in pairs(self.__supers) do
        s:ctor(app)
    end
end 

return TestAction
