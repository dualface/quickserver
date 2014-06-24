
local ServerAppBase = import(".ServerAppBase")

local HttpServerBase = class("HttpServerBase", ServerAppBase)

function HttpServerBase:ctor(config)
    HttpServerBase.super.ctor(self, config)

    self.config.requestType = "http"

    self.requestMethod = ngx.req.get_method()
    self.requestParameters = ngx.req.get_uri_args()
    if self.requestMethod == "POST" then
        ngx.req.read_body()
        table.merge(self.requestParameters, ngx.req.get_post_args())
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

end

return HttpServerBase
