local json_decode = json.decode
local json_encode = json.encode
local tostring = tostring
local os_date = os.date

local _JOB_HASH = "_JOB_HASH"

local RedisService = cc.load("redis").service
local BeansService = cc.load("beanstalkd").service
local JobService = cc.load("job").service

local JobworkerAction = class("Jobworker")

function JobworkerAction:ctor(cmd)
    self._cmd = cmd
    self._jobTube = cmd.config.beanstalkd.jobTube
    self._jobService = JobService:create(self:_getRedis(), self:_getBeans(), self._jobTube)
end

function JobworkerAction:handleAction(arg)
    local beans = self:_getBeans()
    local redis = self:_getRedis()
    local jobService = self._jobService

    self:_recoverJobs()

    beans:command("watch", self._jobTube)

    while true do
        local job, err = beans:command("reserve")
        if not job then
            printWarn("reserve beanstalkd job failed: %s", err)
            if err == "NOT_CONNECTED" then
                throw("beanstalkd NOT_CONNECTED")
            end
            goto reserve_next_job
        end

        local data, err = json_decode(job.data)
        if not data then
            printWarn("job bid: %s,  contents: \"%s\" is invalid: %s", job.id, job.data, err)
            beans:command("delete", job.id)
            goto reserve_next_job
        end

        printInfo("get a job, jobId: %s, contents: %s", tostring(data.id), job.data)

        -- remove redis data, which is related to this job
        jobService:remove(data.id)

        -- handle this job
        local jobAction = data.action
        res = self._cmd:runAction(jobAction, data.arg)
        if self._cmd.config.appJobMessageFormat == "json" then
            res = json_encode(res)
        end

        printf("finish job, jobId: %s, start_time: %s, end_time:%s, result: %s", tostring(data.id), data.start_time, os_date("%Y-%m-%d %H:%M:%S"), res)

::reserve_next_job::
    end

end

function JobworkerAction:_recoverJobs()
    local redis = self:_getRedis()
    local jobService = self._jobService

    local res, err = redis:command("HGETALL", _JOB_HASH)
    if not res then
        printWarn("recover jobs from db faild: %s", err)
        return
    end

    for i = 2, #res, 2 do
        local job, err = json_decode(res[i])
        if job then
            local id
            id, err = JobService:add(job.action, job.arg, job.delay, job.priority, job.ttr)
            if id then
                printInfo("recover job success, old job id: %s, new job id: %s", res[i-1], tostring(id))
            end
        end

        if err then
            printWarn("recover job failed: %s. job id: %s, contents: %s", err, res[i-1], res[i])
        end
    end

    printInfo("recover jobs finished.")
end

function JobworkerAction:_getBeans()
    if not self._beans then
        self._beans = self:_newBeans()
    end
    return self._beans
end

function JobworkerAction:_newBeans()
    local beans = BeansService:create(self._cmd.config.beanstalkd)
    local ok, err = beans:connect()
    if err then
        throw("connect internal beanstalkd failed, %s", err)
    end
    return beans
end

function JobworkerAction:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function JobworkerAction:_newRedis()
    local redis = RedisService:create(self._cmd.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return JobworkerAction
