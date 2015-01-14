local JobAction = class("JobAction")

local function err_(...)
    return {err_msg = strFormat(...)}
end

local service = import(".service")

function JobAction:ctor(app)
    self.jobService = service.new(app)
end

function JobAction:newjobAction(data)
    local s = self.jobService
    if not s then
        return err_("JobAction is not initialized.")
    end

    local ok, err = s:newJob(data)
    if not ok then 
        return err_(err)
    end

    return {ok = 1}
end

return JobAction
