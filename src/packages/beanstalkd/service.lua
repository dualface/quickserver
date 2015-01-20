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

local type = type

local BeanstalkdService = class("BeanstalkdService")

local adapter
if ngx then
    adapter = import(".adapter.RestyBeanstalkdAdapter")
else
    adapter = import(".adapter.BeanstalkdHaricotAdapter")
end

function BeanstalkdService:ctor(config)
    if not config or type(config) ~= "table" then
        return nil, "config is invalid."
    end

    self.config = config or {host = "127.0.0.1", port = "11300", timeout = 10 * 1000}

    self.beans = adapter.new(config)
end

function BeanstalkdService:connect()
    local beans = self.beans
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    return beans:connect()
end

function BeanstalkdService:close()
    local beans = self.beans
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    return beans:close()
end

function BeanstalkdService:command(command, ...)
    local beans = self.beans
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    return beans:command(command, ...)
end

return BeanstalkdService
