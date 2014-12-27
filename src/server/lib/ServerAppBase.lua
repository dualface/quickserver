
local ServerAppBase = class("ServerAppBase")

ServerAppBase.APP_RUN_EVENT          = "APP_RUN_EVENT"
ServerAppBase.APP_QUIT_EVENT         = "APP_QUIT_EVENT"
ServerAppBase.CLIENT_ABORT_EVENT     = "CLIENT_ABORT_EVENT"

function ServerAppBase:ctor(config)
    cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self.isRunning = true
    self.config = clone(totable(config))
    self.config.appModuleName = config.appModuleName or "app"
    self.config.actionPackage = config.actionPackage or "actions"
    self.config.actionModuleSuffix = config.actionModuleSuffix or "Action"

    -- check session id for WebSocket
    self.checkedSessionId = false 

end

function ServerAppBase:run()
    self:dispatchEvent({name = ServerAppBase.APP_RUN_EVENT})
    local ret = self:runEventLoop()
    self.isRunning = false
    self:dispatchEvent({name = ServerAppBase.APP_QUIT_EVENT, ret = ret})
end

function ServerAppBase:runEventLoop()
    throw(ERR_SERVER_OPERATION_FAILED, "ServerAppBase:runEventLoop() - must override in inherited class")
end

function ServerAppBase:doRequest(actionName, data, userDefModule)
    local actionPackage = self.config.actionPackage
    if userDefModule then
        actionPackage = userDefModule .. ".actions"
    end

    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionModuleName = string.format("%s.%s%s", actionPackage, string.ucfirst(string.lower(actionModuleName)), self.config.actionModuleSuffix)
    actionMethodName = string.ucfirst(string.lower(actionMethodName)) .. "Action"

    local actionModule = self:require(actionModuleName, userDefModule)
    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        throw(ERR_SERVER_INVALID_ACTION, "failed to load action module %s", actionModuleName)
    end

    local action = actionModule.new(self)
    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw(ERR_SERVER_INVALID_ACTION, "invalid action %s:%s", actionModuleName, actionMethodName)
    end

    if not data then
        data = self.requestParameters or {}
    end

    if not self:checkSessionId(data, actionMethodName, actionModuleName) then
        throw(ERR_SERVER_INVALID_SESSION_ID, "session id is invalid or does NOT exist when calling %s:%s.", actionModuleName, actionMethodName)
    end

    return method(action, data)
end

function ServerAppBase:checkSessionId(data, action, module)
    if action == "SessionAction" and string.find(module, "UserAction") then
        return true
    end

    -- cause "FriendshipAction" is associated with weibo.
    if string.find(module, "FriendshipAction") then
        return true
    end

    -- in subsequent WebSocket reqs, this value should be true. 
    if self.checkedSessionId then 
        return true
    end

    if data.session_id == nil or data.session_id == "" then
        return false
    end

    local findSql = string.format([[select uid, ip from user_info where session_id = '%s';]], data.session_id)

    local mysql = self:getMysql()
    local redis = self:getRedis()

    local res, err = mysql:query(findSql)
    if not res or next(res) == nil then
        redis:command("hdel", "__token_expire", data.session_id)
        return false
    end
    local uid = res[1].uid
    local ip = res[1].ip

    if ip ~= ngx.var.remote_addr then
        echoInfo("ip from session_id is not same as remote client ip.")
        return false
    end

    -- "__token_expire" is a hash for storing last updated time of token.
    local lastTime = redis:command("hget", "__token_expire", data.session_id)
    local now = os.time()
    if not lastTime or not tonumber(lastTime) or (now-tonumber(lastTime)) > self.config.sessionExpired then
        echoInfo("session_id is EXPIRED.")
        redis:command("hdel", "__token_expire", data.session_id)
        local delSql = string.format([[delete from user_info where session_id = '%s';]], data.session_id);
        mysql:query(delSql)

        return false
    else
        redis:command("hset", "__token_expire", data.session_id, now)
    end
    
    -- if the req is though WebSocket, flag it.
    self.checkedSessionId = true

    return true
end

function ServerAppBase:newService(name)
    return self:require(string.format("services.%sService", string.ucfirst(name))).new(self)
end

function ServerAppBase:require(moduleName, userDefModule)
    if userDefModule then
        moduleName = self.config.userDefinedCodes.luaRepoPrefix .. "." .. moduleName
        return require(moduleName)
    end
    moduleName = self.config.appModuleName .. "." .. moduleName
    return require(moduleName)
end

function ServerAppBase:normalizeActionName(actionName)
    local actionName = actionName or (self.GET.action or "index.index")
    actionName = string.gsub(actionName, "[^%a.]", "")
    actionName = string.gsub(actionName, "^[.]+", "")
    actionName = string.gsub(actionName, "[.]+$", "")

    local parts = string.split(actionName, ".")
    if #parts == 1 then parts[2] = 'index' end
    return parts[1], parts[2]
end

function ServerAppBase:newRedis(config)
    local redis = cc.server.RedisEasy.new(config or self.config.redis)
    local ok, err = redis:connect()
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, "failed to connect redis, %s", err)
    end
    return redis
end

function ServerAppBase:getRedis()
    if not self.redis then
        self.redis = self:newRedis()
    end
    return self.redis
end

function ServerAppBase:relRedis()
    if self.redis then
        self.redis:close()
        self.redis = nil
    end
end

function ServerAppBase:newBeanstalkd(config)
    local bean = cc.server.BeanstalkdEasy.new(config or self.config.beanstalkd)
    local ok, err = bean:connect()
    if not ok then
        throw(ERR_SERVER_OPERATION_FAILED, "failed to connect beanstalkd, %s", err)
    end
    return bean
end

function ServerAppBase:getBeanstalkd()
    if not self.beanstalkd then
        self.beanstalkd = self:newBeanstalkd()
    end
    return self.beanstalkd
end

function ServerAppBase:newMysql(config)
    local mysql, err = cc.server.MysqlEasy.new(config or self.config.mysql)

    if err then
        throw(ERR_SERVER_OPERATION_FAILED, "failed to connect mysql, %s", err)
    end

    return mysql
end

function ServerAppBase:getMysql()
    if not self.mysql then
        self.mysql = self:newMysql()
        return self.mysql
    end

    if not ngx then
        self.mysql:close()
        self.mysql = nil
        self.mysql = self:newMysql()
    end

    return self.mysql
end

function ServerAppBase:relMysql()
    if self.mysql then 
        self.mysql:close()
        self.mysql = nil
    end
end

function ServerAppBase:newRankList() 
    local rankList = cc.server.RankList.new()

    return rankList
end 

function ServerAppBase:getRankList() 
    if not self.rankList then 
        self.rankList = self:newRankList()
        return self.rankList
    end

    return self.rankList
end 

return ServerAppBase

