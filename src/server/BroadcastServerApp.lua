DEBUG = 2 

local BackgroundWorkerApp = class("BackgroundWorkerApp", cc.server.ServerAppBase)

function BackgroundWorkerApp:ctor(config)
    BackgroundWorkerApp.super.ctor(self, config)

    self.config.actionPackage = "workers"
    self.config.actionModuleSuffix = "Worker"
end

function BackgroundWorkerApp:doRequest(actionName, data)
    return pcall(function()
        return BackgroundWorkerApp.super.doRequest(self, actionName, data)
    end, function(msg) return msg end)
end

function BackgroundWorkerApp:runEventLoop()
    local redis = cc.load("redis").service.new(self.config.redis)
    local bean = cc.load("beanstalkd").service.new(self.config.beanstalkd)
    local jobTube = self.config.broadcastJobTube

    while true do 
        bean:connect()
        redis:connect()

        local ok, err = bean:command("watch", jobTube)
        if not ok then
            printWarn("watch tube [%s] failed [%s]", jobTube, err)
        end

        while ok do
            local job
            jobId, jobData = bean:command("reserve")
            if jobId then
                printInfo("get job [%s] from tube [%s], job data [%s]", jobId, jobTube, jobData)
                local data, err = self:parseJobData_(jobData)
                if data then
                    local actionName = data.action
                    local _, result = self:doRequest(actionName, data)
                    printInfo("job [%s] is finished, action name [%s], result [%s]", jobId, actionName, json.encode(result)) 

                    local reply = {}
                    reply.job_id = data.job_id
                    reply.start_time = data.start_time
                    reply.payload = result
                    reply.owner = data.owner
                    printInfo("job [%s] reply[%s] will be sent to job channel [%s]", jobId, json.encode(reply), data.channel) 

                    redis:command("publish", data.channel, json.encode(reply))
                    bean:command("delete", jobId)
                else 
                    printInfo("parse job [%s] failed [%s]", jobId, err) 
                    bean:command("delete", jobId)
                end
            else  
                printWarn("reserve from tube [%s] failed [%s]", jobTube, jobData)                
                break
            end
        end

        bean:close()
        redis:close()

        -- if beastalkd crashes, worker should have a try to connect it at the intervals of 60s.
        ngx.sleep(self.config.broadcastJobRetryInterval)
    end
end

function BackgroundWorkerApp:parseJobData_(rawData)
    if self.config.jobMessageFormat == "json" then
        local data = json.decode(rawData)
        if type(data) == "table" then
            return data, nil 
        else
            return false, string.format("invalid job data [%s]", tostring(rawData))
        end
    else
        return false, string.format("not support message format [%s]", tostring(self.config.jobMessageFormat))
    end
end

return BackgroundWorkerApp
