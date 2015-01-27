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

local HttpServerApp = class("HttpServerApp", cc.server.HttpServerBase)

function HttpServerApp:ctor(config)
    HttpServerApp.super.ctor(self, config)

    printInfo("---------------- START -----------------")

    self:addEventListener(HttpServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)
end

function HttpServerApp:doRequest(actionName, data)
    printInfo("HttpServerApp:doRequest, ACTION >> call [%s]", actionName)

    local _, result = xpcall(function()
        return HttpServerApp.super.doRequest(self, actionName, data)
    end,
    function(err)
        local beg, rear = string.find(err, "module.*not found")
        if beg then
            err = string.sub(err, beg, rear)
        end
        return {error = string.format([[HttpServerApp:doRequest, Handle http request failed: %s]], string.gsub(err, [[\]], ""))}
    end)

    local j = json.encode(result)
    printInfo("HttpServerApp:doRequest, ACTION << ret  [%s] = (%d bytes) %s", actionName, string.len(j), j)

    return result
end

-- events callback
-- dummy here
function HttpServerApp:onClientAbort(event)

end

return HttpServerApp
