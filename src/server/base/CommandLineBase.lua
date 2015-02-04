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

local ActionDispatcher = import(".ActionDispatcher")
local CommandLineBase = class("CommandLineBase", ActionDispatcher)

function CommandLineBase:ctor(config, arg)
    CommandLineBase.super.ctor(self, config)

    self._requestType = Constants.CLI_REQUEST_TYPE
    self._requestParameters = checktable(arg)
end

function CommandLineBase:run()
    local result, err = self:runEventLoop()

    local rtype = type(result)
    if not err then
        if rtype == "nil" then
            ngx.status = ngx.HTTP_OK
            return
        elseif rtype == "string" then
            ngx.status = ngx.HTTP_OK
            ngx_say(result)
            return
        end
    end

    local result, err = self:_genOutput(result, err)
    if err then
        -- return an error page with custom contents
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx_say(err)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.status = ngx.HTTP_OK
        if result then ngx_say(result) end
    end
end

function CommandLineBase:runEventLoop()
end

return CommandLineBase
