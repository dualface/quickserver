local HttpServerApp = class("HttpServerApp", cc.server.HttpServerBase)

function HttpServerApp:ctor(config)
    HttpServerApp.super.ctor(self, config)

    if self.config.debug then
        printInfo("---------------- START -----------------")
    end

    self:addEventListener(HttpServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)

end

function HttpServerApp:doRequest(actionName, data, userDefModule)
    if self.config.debug then
        printInfo("ACTION >> call [%s]", actionName)
    end

    local _, result = xpcall(function()
                                 return HttpServerApp.super.doRequest(self, actionName, data, userDefModule)
                             end,
                             function(err)
                                 local beg, rear = string.find(err, "module.*not found") 
                                 if beg then 
                                     err = string.sub(err, beg, rear)
                                 end
                                 return {error = string.format([[Handle http request failed: %s]], string.gsub(err, [[\]], ""))}
                             end)

    if self.config.debug then
        local j = json.encode(result)
        printInfo("ACTION << ret  [%s] = (%d bytes) %s", actionName, string.len(j), j)
    end

    return result
end

-- events callback
-- dummy here
function HttpServerApp:onClientAbort(event)

end

return HttpServerApp
