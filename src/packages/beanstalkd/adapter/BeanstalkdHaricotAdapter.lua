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

local haricot = require("3rd.beanstalkd.haricot")

local BeanstalkdHaricotAdapter = class("BeanstalkdHaricotAdapter")

function BeanstalkdHaricotAdapter:ctor(config)
    self.config = config
    self.instance = haricot.new(self.config.host, self.config.port)
end

function BeanstalkdHaricotAdapter:connect()
    return true
end

function BeanstalkdHaricotAdapter:close()
    if not self.instance then return false, self.ctorErr end
    return self.instance:quit()
end

function BeanstalkdHaricotAdapter:command(command, ...)
    if not self.instance then return false, self.ctorErr end
    local method = self.instance[command]
    assert(type(method) == "function", strFormat("BeanstalkdHaricotAdapter:command() - invalid command %s", tostring(command)))
    local ok, result = method(self.instance, ...)
    if ok then return result end
    return false, result
end

return BeanstalkdHaricotAdapter
