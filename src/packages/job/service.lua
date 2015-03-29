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

local pairs = pairs
local tonumber = tonumber
local type = type
local table_nums = table.nums
local json_encode = json.encode
local json_decode = json.decode
local os_date = os.date
local string_format = string.format
local string_gsub = string.gsub

local jobKey = "job_key_"
local jobHashList = "job_hashlist_"
local jobActionListPattern = "job_%s_sets_"

local JobService = class("JobService")

function JobService:ctor(redis, beans, jobTube)
    if not redis or not beans then
        throw("job service is initialized failed: redis or beans is invalid.")
    end
    if not jobTube then
        throw("job Service is initialized failed: job tube is null.")
    end
    self._redis = redis
    self._beans = beans
    self._jobTube = jobTube
end

local function checkParams_(data, ...)
    local arg = {...}

    if table_nums(arg) == 0 then
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
        return nil, string_format("generate job id failed: %s", err)
    end

    data.rid = jobRid
    data.start_time = os_date("%Y-%m-%d %H:%M:%S")
    data.action = nil
    data.msg_id = nil

    -- put job to beanstalkd
    bean:connect()
    bean:command("use", self.jobTube)
    local jobBid
    jobBid, err = bean:command("put", json_encode(data), tonumber(data.priority), tonumber(data.delay))
    if not jobBid then
        redis:close()
        bean:close()
        return nil, string_format("put job to beanstalkd failed: %s", err)
    end
    bean:close()

    -- store job info to redis for persistence
    data.bid = jobBid
    local ok, err = redis:command("HSET", jobHashList, jobRid, json_encode(data))
    if not ok then
        printWarn("JobService:newJob() - store job to redis failed: %s", err)
    end

    -- index actions for findJob service interface
    local jobActionList = string_format(jobActionListPattern, string_gsub(data.job.action, "%.", "_"))
    local ok, err = redis:command("SADD", jobActionList, data.rid)
    if not ok then
        printWarn("JobService:newJob() - index actions to %s failed: %s", jobActionList, err)
    end
    redis:close()

    return jobRid, nil
end

function JobService:getJob(rid)
    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    redis:connect()
    local job, err = redis:command("HGET", jobHashList, rid)
    redis:close()
    if not job then
        return nil, string_format("get job failed: %s", err)
    end
    if ngx and job == ngx.null then
        return nil, string_format("job[%d] does not exist.", rid)
    end

    return job, nil
end

function JobService:findJob(actionName)
    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    redis:connect()
    local jobActionList = string_format(jobActionListPattern, string_gsub(actionName, "%.", "_"))
    local ridList, err = redis:command("SMEMBERS", jobActionList)
    redis:close()
    if not ridList then
        return nil, string_format("find job failed: %s", err)
    end
    if next(ridList) == nil then
        return nil, string_format("can't find jobs with action %s", actionName)
    end

    return ridList, nil
end

function JobService:removeJob(rid)
    local redis = self.redis
    if redis == nil then
        return nil, "Service redis is not initialized."
    end

    local bean = self.bean
    if bean == nil then
        return nil, "Service beanstalkd is not initialized."
    end

    redis:connect()
    local jobStr, err = redis:command("HGET", jobHashList, rid)
    if not jobStr then
        return nil, string_format("get job failed: %s", err)
    end
    if ngx and jobStr == ngx.null then
        redis:close()
        return nil, string_format("job[%d] does not exist.", rid)
    end

    -- delete it from redis
    redis:command("HDEL", jobHashList, rid)

    job, err = json_decode(jobStr)
    if not job then
        redis:close()
        printWarn("JobService:removeJob() - josn decode job failed: %s, job contents: %s", err, jobStr)
        return nil, string_format("job[%d] is invalid.", rid)
    end

    local jobAction = job.job.action
    local jobActionList = string_format(jobActionListPattern, string_gsub(jobAction, "%.", "_"))
    local ok , err = redis:command("SREM", jobActionList, rid)
    redis:close()
    if not ok then
        printWarn("JobService:removeJob() - redis set delete failed: %s", err)
    end

    -- delete it from beanstalkd
    bean:connect()
    local bid = job.bid
    local ok, err = bean:command("delete", tonumber(bid))
    bean:close()

    return true, nil
end

return JobService
