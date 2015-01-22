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
            printError("job [%s] parse message failed: %s, message: %s", job.id, err, job.data)
            bean:command("delete", job.id)
        else
            local execJob = data.job
            local actionName = execJob.action
            local _, result = self:doRequest(actionName, execJob)
            if self.config.debug then
                printInfo("job [%s] [%s], run action %s finished.", job.id, data.bid, actionName)
            end

            local rid = data.rid
            local jobService = cc.load("job").service.new(self.config)
            jobService:removeJob(rid)

            local reply = {}
            reply.job_id = rid
            reply.start_time = data.start_time
            reply.stop_time = os.date("%Y-%m-%d %H:%M:%S")
            reply.payload = result
            local to = data.to
            reply.to = to

            local repMsg = json.encode(reply)

            for _, v in ipairs(to) do
                local sid = self:getSidByTag(v)
                if sid then
                    self:sendMessage(sid, repMsg)
                    printInfo("reply = %s, to: %s, sid = %s", repMsg, v, sid)
                end
            end
        end

::reserve_next_job::

    end

    bean:close()
    redis:close()
end

function CmdBroadcastWorker:parseJobMessage(rawMessage)
    if self.config.jobMessageFormat == "json" then
        local message = json.decode(rawMessage)
        if type(message) == "table" then
            return message, nil
        else
            return false, string.format("invalid message, %s", tostring(rawMessage))
        end
    else
        return false, string.format("not support message format %s", tostring(self.config.jobMessageFormat))
    end
end

return CmdBroadcastWorker
