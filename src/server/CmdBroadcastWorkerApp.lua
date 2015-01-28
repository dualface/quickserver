--[[

Copyright (c) 2011-2015 chukong-inc.com

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

local type = type
local pcall = pcall
local tostring = tostring
local string_format = string.format
local json_encode = json.encode
local os_date = os.date

local CmdBroadcastWorker = class("CmdBroadcastWorker", cc.server.CommandLineServerBase)

function CmdBroadcastWorker:ctor(config)
    CmdBroadcastWorker.super.ctor(self, config)
    self.config.actionPackage = "workers"
    self.config.actionModuleSuffix = "Worker"
end

function CmdBroadcastWorker:doRequest(actionName, data)
    return pcall(function()
        return CmdBroadcastWorker.super.doRequest(self, actionName, data)
    end, function(msg) return msg end)
end

function CmdBroadcastWorker:runEventLoop()
    -- connect to beanstalkd, supervisor a tube
    local bean = cc.load("beanstalkd").service.new(self.config.beanstalkd)
    bean:connect()
    local ok, err = bean:command("watch", self.config.broadcastJobTube)
    if not ok then
        printError("CmdBroadcastWorker:runEventLoop() - watch beanstalkd tube failed: %s", err)
        bean:close()
        return
    end

    -- connect to redis
    local redis = cc.load("redis").service.new(self.config.redis)
    redis:connect()

    while true do
        local job, err = bean:command("reserve")

        if err then
            printError("CmdBroadcastWorker:runEventLoop() - reserve beanstalkd job failed: %s", err)
            if err == "NOT_CONNECTED" then
                break
            end
            goto reserve_next_job
        end

        local data, err = self:parseJobMessage(job.data)
        if not data then
            printError("CmdBroadcastWorker:runEventLoop() - job [%s] parse message failed: %s, message: %s", job.id, err, job.data)
            bean:command("delete", job.id)
        else
            printInfo("CmdBroadcastWorker:runEventLoop() - get job [%s], contents: %s", job.id, job.data)

            -- remove redis data, which is related to this job
            local jobService = cc.load("job").service.new(self.config)
            jobService:removeJob(data.rid)

            -- as current connection is not end and reservd a job,
            -- job service can't delete this job via another connection
            bean:command("delete", job.id)

            -- handle this job
            local execJob = data.job
            local actionName = execJob.action
            local _, result = self:doRequest(actionName, execJob)
            printInfo("CmdBroadcastWorker:runEventLoop() - job [%s], run action %s finished.", job.id, data.bid, actionName)

            -- send message
            local reply = {}
            reply.job_id = data.rid
            reply.start_time = data.start_time
            reply.stop_time = os_date("%Y-%m-%d %H:%M:%S")
            reply.payload = result
            local to = data.to
            local repMsg = json_encode(reply)
            for _, v in ipairs(to) do
                local sid = self:getSidByTag(v)
                if sid then
                    self:sendMessage(sid, repMsg)
                    printInfo("CmdBroadcastWorker:runEventLoop() - reply = %s, sent to: %s, sid = %s", repMsg, v, sid)
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
            return false, string_format("invalid message, %s", tostring(rawMessage))
        end
    else
        return false, string_format("not support message format %s", tostring(self.config.jobMessageFormat))
    end
end

return CmdBroadcastWorker
