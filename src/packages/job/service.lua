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
