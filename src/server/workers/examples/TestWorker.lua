local leaderboardAction = cc.load("leaderboard").action
local chatAction = cc.load("chat").action

local TestAction = class("TestAction", leaderboardAction, chatAction)

function TestAction:ctor(app)
    for _, s in pairs(self.__supers) do
        s:ctor(app)
    end
end

function TestAction:sayhelloAction(data)
    return {hello = data.name}
end

return TestAction
