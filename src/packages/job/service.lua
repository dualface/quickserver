local tabLength = table.nums
local jsonEncode = json.encode
local localtime = ngx.localtime

local JobService = class("JobService")

function JobService:ctor(app)
    local config = nil
    if app then 
        config = app.config.beanstalkd
    end
    self.bean = cc.load("beanstalkd").service.new(config)
    self.bean:connect()
    self.bean:command("use", app.config.broadcastJobTube) 

    self.channel = app.jobChannel
    self.owner = app.websocketUid
end

local function checkParams_(data, ...)
    local arg = {...} 

    if tabLength(arg) == 0 then 
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

    if not checkParams_(data, "job", "delay") then 
        return nil, "'job' or 'delay' is missed in param table."
    end 
    
    local job = data.job
    job.start_time = localtime()
    job.channel = self.channel  -- which the result is published to
    job.owner = self.owner

    bean:command("put", jsonEncode(job), tonumber(data.priority), tonumber(data.delay))

    return true, nil 
end

return JobService
