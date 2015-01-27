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
local tostring = tostring
local ngx = ngx
local ngx_say = ngx.say
local req_get_headers = ngx.req.get_headers
local req_get_body_data = ngx.req.get_body_data
local req_get_method = ngx.req.get_method
local req_get_uri_args = ngx.req.get_uri_args
local req_read_body = ngx.req.read_body
local req_get_post_args = ngx.req.get_post_args
local table_merge = table.merge
local string_gsub = string.gsub

local HttpServerBase = class("HttpServerBase", import(".ServerAppBase"))

function HttpServerBase:ctor(config)
    HttpServerBase.super.ctor(self, config)

    self._requestType = "http"
    self._uri = ngx.var.uri
    self._requestMethod = req_get_method()
    self._requestParameters = req_get_uri_args()

    if self._requestMethod == "POST" then
        req_read_body()
        -- handle json body
        local headers = req_get_headers()
        if headers["Content-Type"] == "application/json" then
            local body = req_get_body_data()
            --[[
            This function returns nil if

            - the request body has not been read,
            - the request body has been read into disk temporary files,
            - or the request body has zero size.

            If the request body has not been read yet, call ngx.req.read_body first
            (or turned on lua_need_request_body to force this module to read the
            request body. This is not recommended however).

            If the request body has been read into disk files, try calling
            the ngx.req.get_body_file function instead.

            To force in-memory request bodies, try setting client_body_buffer_size
            to the same size value in client_max_body_size.
            ]]
            if body then
                body = json.decode(body)
                if body then
                    table_merge(self._requestParameters, body)
                else
                    printWarn("HttpServerBase:ctor() - invalid JSON content")
                end
            end
        else
            table_merge(self._requestParameters, req_get_post_args())
        end
    end

    local ok, err = ngx.on_abort(function()
        self:dispatchEvent({name = ServerAppBase.CLIENT_ABORT_EVENT})
    end)
    if not ok then
        printWarn("HttpServerBase:ctor() - failed to register the on_abort callback: %s ", err)
    end
end

-- actually it is not a loop, since it is based on HTTP.
function HttpServerBase:runEventLoop()
    local uri = self._uri
    local action = string_gsub(uri, "/", ".")
    if DEBUG > 1 then
        printInfo("HttpServerBase:runEventLoop() - action: %s", action)
        self:dumpRequestParameters()
    end

    local result = self:doRequest(action, self._requestParameters)
    if result then
        local rtype = type(result)
        if rtype == "string" then
            ngx_say(result)
        elseif rtype == "table" then
            ngx_say(json.encode(result))
        else
            ngx_say("unexpected result: ", tostring(result))
        end
    end
end

function HttpServerBase:dumpRequestParameters()
    printInfo("HttpServerBase:runEventLoop() - params: %s", json.encode(self._requestParameters))
end

return HttpServerBase
