local leaderboardAction = cc.load("leaderboard").action
local storageActon = cc.load("objectstorage").action
local chatAction = cc.load("chat").action
local jobAction = cc.load("job").action

local TestAction = class("TestAction", storageActon, leaderboardAction, chatAction, jobAction)

function TestAction:ctor(app)
    for _, s in pairs(self.__supers) do
        s:ctor(app)
    end
end 

return TestAction
