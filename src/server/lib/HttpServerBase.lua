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

local ServerAppBase = import(".ServerAppBase")

local HttpServerBase = class("HttpServerBase", ServerAppBase)

function HttpServerBase:ctor(config)
    HttpServerBase.super.ctor(self, config)

    self.requestType = "http"
    self.uri = ngx.var.uri
    self.requestMethod = ngx.req.get_method()
    self.requestParameters = ngx.req.get_uri_args()

    if self.requestMethod == "POST" then
        ngx.req.read_body()
        -- handle json body
        local conType = ngx.req.get_headers(0)["Content-Type"]
        if conType == "application/json" then
            local body = json.decode(ngx.req.get_body_data())
            --since 'table.merge' is implemented stupid, can't use here to merge a complex json table.
            --TODO: need re-implement 'table.merge'
            --table.merge(self.requestParameters, body)
            self.requestParameters = body
        else
            table.merge(self.requestParameters, ngx.req.get_post_args())
        end
    end

    local ok, err = ngx.on_abort(function()
        self:dispatchEvent({name = ServerAppBase.CLIENT_ABORT_EVENT})
    end)
    if not ok then
        printInfo("failed to register the on_abort callback, ", err)
    end

    if self.config.session then
        self.session = cc.server.Session.new(self)
    end
end

-- actually it is not a loop, since it is based on http.
function HttpServerBase:runEventLoop()
    local uri = self.uri
    local rawAction = string.gsub(uri, "/", ".")

    printInfo("requst via HTTP,  Action: %s", rawAction)
    self:dumpParams()

    if rawAction == "session" then
        local sid = self.newSessionId(self.requestParameters)
        ngx.say(sid)
        return
    end

    local result = self:doRequest(rawAction, self.requestParameters)

    -- simple http rsp
    if result  then
        if type(result) == "string" then
            ngx.say(result)
        elseif type(result) == "table" then
            ngx.say(json.encode(result))
        else
            ngx.say("unexpected result: ", tostring(result))
        end
    end
end

-- for debug
function HttpServerBase:dumpParams()
    printInfo("DUMP HTTP params: %s", json.encode(self.requestParameters))
end

return HttpServerBase
