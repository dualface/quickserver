--[[

Copyright (c) 2011-2015 chukong-inc.com

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
local ngx = ngx
local ngx_say = ngx.say
local string_find = string.find
local string_gsub = string.gsub
local string_len = string.len
local string_format = string.format
local string_sub = string.sub
local json_encode = json.encode

local WebSocketServerApp = class("WebSocketServerApp", cc.server.WebSocketsServerBase)

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    printInfo("---------------- START -----------------")

    self:addEventListener(WebSocketServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)
    self:addEventListener(ServerAppBase.APP_QUIT_EVENT, self.onAppQuit, self)
end

function WebSocketServerApp:doRequest(actionName, data)
    printInfo("WebSocketServerApp:doRequest() - ACTION >> call [%s]", actionName)

    local _, result = xpcall(function()
        return WebSocketServerApp.super.doRequest(self, actionName, data)
    end,
    function(err)
        local beg, rear = string_find(err, "module.*not found")
        if beg then
            err = string_sub(err, beg, rear)
        end
        return {error = string_format([[Handle request failed: %s]], string_gsub(err, [[\]], ""))}
    end)

    if DEBUG > 1 then
        printInfo("WebSocketServerApp:doRequest() - ACTION << ret  [%s](%d bytes): %s", actionName, string_len(json_encode(j)), json_encode(j))
    end

    return result
end

---- events callback

function WebSocketServerApp.onAppQuit(event)
    printInfo("---------------- QUIT -----------------")

    local ret = event.ret
    ngx.status = ret
    ngx_say("websocket connection end")
end

-- dumb here
function WebSocketServerApp.onClientAbort(event)
end

return WebSocketServerApp
