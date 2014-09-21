
local ServerAppBase = import(".ServerAppBase")

local HttpServerBase = class("HttpServerBase", ServerAppBase)

local function GetActionFromURI(uri, uriPrefix) 
    local prefix = uriPrefix 
    local userDefModule = nil
    if type(uriPrefix) == "table" then  
        for k,v in pairs(prefix) do 
            if string.find(string.upper(uri), string.upper(v)) then 
                prefix = v
                userDefModule = k
                break
            end
        end
    end

    local action = nil
    if type(prefix) ~= "table" then 
        echoInfo(type(prefix))
        local pos = string.find(string.upper(uri), string.upper(prefix)) 
        action = string.sub(uri, pos+string.len(prefix)+1, -1)
    else 
       echoInfo("Can't get actions from uri.") 
       return "", nil
    end

    return string.gsub(action, "/", "."), userDefModule 
end

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

-- actually it is not a loop, since it is based on http.
function HttpServerBase:runEventLoop()
    -- "/_SERVER/*" points to default local service.
    local LOCAL_URI_PREFIX = [[_SERVER]]

    local uriPrefix = self.config.userDefinedCodes.uriPrefix
    local uri = self.uri
    local rawAction = {}
    if string.find(string.upper(uri), LOCAL_URI_PREFIX) then
        rawAction.action = GetActionFromURI(uri, LOCAL_URI_PREFIX)  
    else 
        rawAction.action, rawAction.userDefModule = GetActionFromURI(uri, uriPrefix)
    end
    
    echoInfo("requst via HTTP,  Action: %s", rawAction.action)
    self:dumpParams()

    local result = self:doRequest(rawAction.action, self.requestParameters, rawAction.userDefModule)

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
    
    -- replease mysql & redis connections
    self:relRedis()
    self:relMysql()
end

-- for test
function HttpServerBase:dumpParams()
    echoInfo("DUMP HTTP params: %s", json.encode(self.requestParameters))

end

return HttpServerBase
