local BackgroundWorkerApp = class("BackgroundWorkerApp", cc.server.CommandLineServerBase)

function BackgroundWorkerApp:ctor(config)
    BackgroundWorkerApp.super.ctor(self, config)
    self.config.workerMaxRequestCount = config.workerMaxRequestCount or 100
    self.config.actionPackage = "workers"
    self.config.actionModuleSuffix = "Worker"

    self.redis = cc.load("redis").service.new(config.redis)
    self.redis:connect()

    self.bean = cc.load("beanstalkd").service.new(config.beanstalkd)
    self.bean:connect()
end

function BackgroundWorkerApp:doRequest(actionName, data)
    return pcall(function()
        return BackgroundWorkerApp.super.doRequest(self, actionName, data)
    end, function(msg) return msg end)
end

function BackgroundWorkerApp:runEventLoop()
    -- connect to beanstalkd, wait job
    local bean = self.bean
    bean:command("watch", self.config.workQueue)

    local redis = self.redis

    while true do
        local job, err = bean:command("reserve")

        if err then
            printError(err)
            if err == "NOT_CONNECTED" then
                break
            end
            goto reserve_next_job
        end

        local data, err = self:parseJobMessage(job.data)
        if not data then
            printError("job [%s] parse message failed: %s", job.id, message)
            bean:command("delete", job.id)
        else
            local actionName = data.action
            local _, result = self:doRequest(actionName, data)
            if self.config.debug then
                printInfo("job [%s], run action %s finished.", job.id, actionName)
            end
            bean:command("delete", job.id)

            -- publish to redis channel
            local reply = {}
            reply.job_id = data.job_id
            reply.start_time = data.start_time
            reply.payload = result
            reply.owner = data.owner

            printInfo("reply = %s, data.channel = %s", json.encode(reply), tostring(data.channel))
            redis:command("publish", data.channel, json.encode(reply))
        end

::reserve_next_job::

    end

    bean:close()
end

function BackgroundWorkerApp:parseJobMessage(rawMessage)
    if self.config.workerMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return message, nil 
        else
            return false, string.format("invalid message, %s", tostring(rawMessage))
        end
    else
        return false, string.format("not support message format %s", tostring(self.config.workerMessageFormat))
    end
end

return BackgroundWorkerApp
