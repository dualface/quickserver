
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
        echoInfo("failed to register the on_abort callback, ", err)
    end

    if self.config.session then
        self.session = cc.server.Session.new(self)
    end
end

function HttpServerBase:runEventLoop()
    --ngx.say("call: "..self.uri)
    --ngx.say("uri_prefix: " .. self.config.userDefinedCodes.uriPrefix)

    local uri = self.uri
    local prefixLen = string.len(self.config.userDefinedCodes.uriPrefix)
    local rawAction = string.sub(uri, prefixLen+3, -1)
    rawAction = string.gsub(rawAction, "/", ".")

    echoInfo("requst via HTTP,  Action: %s", rawAction)
    self:dumpParams()

    local result = self:doRequest(rawAction, self.requestParameters)
    if result and type(result) == "table" then
        -- simple http rsp
        ngx.say(json.encode(result))
    end
end

-- for test
function HttpServerBase:dumpParams()
    echoInfo("DUMP HTTP params: %s", json.encode(self.requestParameters))
    --[[
    for k,v in pairs(self.requestParameters) do
        if type(v) == "table" then
            echoInfo("%s : %s", k, table.concat(v, ", "))
            --ngx.say(k, " :", table.concat(v, ", "))
        else
            echoInfo("%s : %s", k, v)
            --ngx.say(k, " :", v)
        end
    end
    --]]
end

return HttpServerBase
