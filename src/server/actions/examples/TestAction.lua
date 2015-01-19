local leaderboardAction = cc.load("leaderboard").action
local storageAction = cc.load("objectstorage").action
local chatAction = cc.load("chat").action
local jobAction = cc.load("job").action

local TestAction = class("TestAction", storageAction, leaderboardAction, chatAction, jobAction)

function TestAction:ctor(app)
    for _, s in pairs(self.__supers) do
        s:ctor(app)
    end
end

function TestAction:sayhelloAction(data)
    return {hello = data.name}
end

return TestAction
