local leaderboardAction = cc.load("leaderboard").action
local storageAction = cc.load("objectstorage").action
local chatAction = cc.load("chat").action

local TestAction = class("TestAction", storageAction, leaderboardAction, chatAction)

function TestAction:ctor(app)
    for _, s in pairs(self.__supers) do
        s:ctor(app)
    end

    self.app = app
end

function TestAction:sayhelloAction(data)
    return {hello = data.name}
end

function TestAction:puttaskAction(data)
    local job = cc.load("job").service.new(self.app.config)

    local ok, err = job:newJob(data)
    if not ok then
        return {error = err}
    end

    return {job_id = ok}
end

function TestAction:findtaskAction(data)
    local job = cc.load("job").service.new(self.app.config)

    local res, err = job:findJob(data.action_name)
    if not res then
        return {error = err}
    end

    return {rid_list = res}
end

function TestAction:removetaskAction(data)
end

return TestAction
