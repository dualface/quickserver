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

local xpcall = xpcall
local string_find = string.find
local string_gsub = string.gsub
local string_len = string.len
local string_format = string.format
local string_sub = string.sub
local json_encode = json.encode

local HttpServerApp = class("HttpServerApp", cc.server.HttpServerBase)

function HttpServerApp:ctor(config)
    HttpServerApp.super.ctor(self, config)

    printInfo("---------------- START -----------------")

    self:addEventListener(HttpServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)
    self:addEventListener(ServerAppBase.APP_QUIT_EVENT, self.onAppQuit, self)
end

function HttpServerApp:doRequest(actionName, data)
    printInfo("HttpServerApp:doRequest() - ACTION >> call [%s]", actionName)

    local _, result = xpcall(function()
        return HttpServerApp.super.doRequest(self, actionName, data)
    end,
    function(err)
        local beg, rear = string_find(err, "module.*not found")
        if beg then
            err = string_sub(err, beg, rear)
        end
        return {error = string_format([[HttpServerApp:doRequest, Handle http request failed: %s]], string_gsub(err, [[\]], ""))}
    end)

    printInfo("HttpServerApp:doRequest() - ACTION << ret  [%s] = (%d bytes) %s", actionName, string_len(json_encode(resutl)), json_encode(resutl))

    return result
end

-- events callback

function HttpServerApp.onAppQuit(event)
    printInfo("---------------- QUIT -----------------")
end

-- dummb here
function HttpServerApp.onClientAbort(event)
end

return HttpServerApp
