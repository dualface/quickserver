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

local assert = assert 
local type = type
local tostring = tostring
local strFormat = string.format

local beanstalkd = require("resty.beanstalkd")

local RestyBeanstalkdAdapter = class("RestyBeanstalkdAdapter")

function RestyBeanstalkdAdapter:ctor(config)
    self.config = config
    self.instance, self.ctorErr = beanstalkd:new()
end

function RestyBeanstalkdAdapter:connect()
    if not self.instance then return false, self.ctorErr end

    local _, err = self.instance:connect(self.config.host, self.config.port)
    if err then
        return false, err
    end
    self.instance:set_timeout(self.config.timeout)
    return true
end

function RestyBeanstalkdAdapter:close()
    if not self.instance then return false, self.ctorErr end

    if self.config.useConnPool then
        return self.instance:set_keepalive(10000, 100)
    end
    return self.instance:close()
end

function RestyBeanstalkdAdapter:command(command, ...)
    if not self.instance then return false, self.ctorErr end
    local method = self.instance[command]
    assert(type(method) == "function", strFormat("RestyBeanstalkdAdapter:command() - invalid command %s", tostring(command)))
    return method(self.instance, ...)
end

return RestyBeanstalkdAdapter
