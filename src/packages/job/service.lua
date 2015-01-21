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

local pairs = pairs
local tonumber = tonumber
local type = type
local tblLength = table.nums
local jsonEncode = json.encode
local localtime = ngx.localtime
local strFormat = string.format

local jobKey = "job_key_"
local jobHashList = "job_hashlist_"
local jobActionListPattern = "job.%s_"

local JobService = class("JobService")

function JobService:ctor(app)
    local config = nil
    if app then
        self.app = app
    end

    self.bean = cc.load("beanstalkd").service.new(app.config.beanstalkd)
    self.redis = cc.load("redis").service.new(app.config.redis)

    self.jobTube = self.config.broadcastJobTube
end

local function checkParams_(data, ...)
    local arg = {...}

    if tblLength(arg) == 0 then
        return true
    end

    for _, name in pairs(arg) do
        if data[name] == nil or data[name] == "" then
           return false
        end
    end

    return true
end

function JobService:newJob(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local bean = self.bean
    if bean == nil then
        return nil, "Service beanstalkd is not initialized."
    end

    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "job", "delay", "to") then
        return nil, "'job', 'delay' or 'to' is missed in param table."
    end

    redis:connect()
    local jobRid, err = redis:command("INCR", jobKey)
    if not jobRid then
        redis:close()
        return nil, strFormat("generate job id failed: %s", err)
    end

    data.rid = jobRid
    data.start_time = localtime()

    bean:connect()
    bean:command("use", self.jobTube)
    local jobBid
    jobBid, err = bean:command("put", jsonEncode(data), tonumber(data.priority), tonumber(data.delay))
    if not jobBid then
        redis:close()
        bean:close()
        return nil, strFormat("put job to beanstalkd failed: %s", err)
    end
    bean:close()

    data.bid = jobBid
    redis:command("HSET", jobHashList, jobRid, jsonEncode(data))
    local jobActionList = strFormat(jobActionListPattern, data.job.action)
    redis:command("RPUSH", jobActionList, rid)
    redis:close()

    return true, nil
end

function JobService:getJob(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "job_id") then
        return nil, "'job_id' is missed in param table."
    end

    local rid = data.job_id
    redis:connect()
    local job, err = redis:command("HGET", jobHashList, rid) 
    redis:close()
    if job == ngx.null then
        return nil, "job does not exist."
    end

    return job, nil
end

function JobService:findJob(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "job_action") then
        return nil, "'job_action' is missed in param table."
    end

    redis:connect()
    local jobActionList = strFormat(jobActionListPattern, data.job_action)
    local ridList, err = redis:command("LRANGE", jobActionList, 1, -1)
    redis:close()
    if not ridList then
        return nil, strFormat("find job failed: %s", err)
    end
    if ridList == ngx.null then
        return "null", nil
    end

    return ridList, nil
end

function JobService:removeJob(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    local bean = self.bean
    if bean == nil then
        return nil, "Service beanstalkd is not initialized."
    end

    if not checkParams_(data, "job_id") then
        return nil, "'job_id' is missed in param table."
    end

    redis:connect()
    local rid = data.job_id
    local job, err = redis:command("HGET", jobHashList, rid)  
    if job == ngx.null then
        return nil, "job does not exists."
    end

    redis:command("HDEL", jobHashList, rid)

    job, err = jsonDecode(job)
    if not job then 
        return nil, "job is invalid."
    end

    local jobAction = job.action
    local jobActionList = strFormat(jobActionListPattern, jobAction)
    redis:command("LREM", jobActionList, 1, rid)
    redis:close()

    bean:connect()
    local bid = job.bid
    bean:command("use", self.jobTube)
    local ok
    ok, err = bean:command("delete", bid)
    bean:close()
    if not ok then
        return nil, "remove job failed: delete it from beanstalkd failed." 
    end

    return true, nil
end

return JobService
