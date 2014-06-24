
local TestWorkerApp = class("TestWorkerApp", cc.server.CommandLineServerBase)

function TestWorkerApp:ctor(config)
    TestWorkerApp.super.ctor(self, config)
    self.config.workerMaxRequestCount = config.workerMaxRequestCount or 100
    self.config.actionPackage = "workers"
    self.config.actionModuleSuffix = "Worker"
    self.requestCount = 0
end

function TestWorkerApp:doRequest(actionName, data)
    return pcall(function()
        return TestWorkerApp.super.doRequest(self, actionName, data)
    end, function(msg) return msg end)
end

function TestWorkerApp:runEventLoop()
    -- connect to beanstalkd, wait job
    local bean = self:getBeanstalkd()
    bean:command("watch", self.config.buildingJobsTube)
    -- bean:command("watch", self.config.removeJobsTube)
    bean:command("watch", self.config.refreshQuestJobsTube)
    bean:command("watch", self.config.questJobsTube)
    bean:command("watch", self.config.trainJobsTube)
    bean:command("watch", self.config.trapJobsTube)
    bean:command("watch", self.config.researchJobsTube)
    bean:command("watch", self.config.marchJobsTube)
    bean:command("watch", self.config.digJobsTube)
    bean:command("watch", self.config.chatJobsTube)
    bean:command("watch", self.config.healJobsTube)

    while true do
        self.requestCount = self.requestCount + 1

        if self.requestCount > self.config.workerMaxRequestCount then
            echoInfo("Worker %s over max requests count, shutdown", tostring(self))
            break
        end

        local job, err = bean:command("reserve")

        if err then
            echoError(err)
            if err == "NOT_CONNECTED" then
                break
            end
            goto reserve_next_job
        end

        local ok, message = self:parseJobMessage(job.data)
        if not ok then
            echoInfo("job [%s] parse message failed: %s", job.id, message)
            bean:command("bury", job.id)
        else
            local actionName = message.action
            local ok, result = self:doRequest(actionName, message)
            if not ok then
                echoError("job [%s], run action %s failed, %s", job.id, actionName, tostring(result))
                bean:command("bury", job.id)
            else
                if self.config.debug then
                    echoInfo("job [%s], run action %s succed.", job.id, actionName)
                end
                if result == true then
                    result = "delete"
                elseif result == nil or result == false then
                    result = "release"
                end
                bean:command(result, job.id)
            end
        end

::reserve_next_job::

    end

    bean:close()
end

function TestWorkerApp:parseJobMessage(rawMessage)
    if self.config.workerMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return true, message
        else
            return false, string.format("invalid message, %s", tostring(rawMessage))
        end
    else
        return false, string.format("not support message format %s", tostring(self.config.workerMessageFormat))
    end
end

return TestWorkerApp
