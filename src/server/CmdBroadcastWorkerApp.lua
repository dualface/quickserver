--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local CmdBroadcastWorker = class("CmdBroadcastWorker", cc.server.CommandLineServerBase)

function CmdBroadcastWorker:ctor(config)
    CmdBroadcastWorker.super.ctor(self, config)
    self.config.workerMaxRequestCount = config.workerMaxRequestCount or 100
    self.config.actionPackage = "workers"
    self.config.actionModuleSuffix = "Worker"

    self.redis = cc.load("redis").service.new(config.redis)
    self.redis:connect()

    self.bean = cc.load("beanstalkd").service.new(config.beanstalkd)
    self.bean:connect()
end

function CmdBroadcastWorker:doRequest(actionName, data)
    return pcall(function()
        return CmdBroadcastWorker.super.doRequest(self, actionName, data)
    end, function(msg) return msg end)
end

function CmdBroadcastWorker:runEventLoop()
    -- connect to beanstalkd, wait job
    local bean = self.bean
    bean:command("watch", self.config.broadcastJobTube)

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
    redis:close()
end

function CmdBroadcastWorker:parseJobMessage(rawMessage)
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

return CmdBroadcastWorker
