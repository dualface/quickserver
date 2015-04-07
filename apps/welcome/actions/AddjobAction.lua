local AddjobAction = class("AddjobAction")

local RedisService = cc.load("redis").service
local BeansService = cc.load("beanstalkd").service
local JobService = cc.load("job").service

function AddjobAction:ctor(con)
    self._cmd = con
    self._jobTube = con.config.beanstalkd.jobTube
end

function AddjobAction:addAction(args)
    local _r = JobService:create(self:_getRedis(), self:_getBeans(), self._jobTube)

    local id = _r:add("testwork.hello", {name=args.name, delay=args.delay}, args.delay)

    return {id = id}
end

function AddjobAction:_getBeans()
    if not self._beans then
        self._beans = self:_newBeans()
    end
    return self._beans
end

function AddjobAction:_newBeans()
    local beans = BeansService:create(self._cmd.config.beanstalkd)
    local ok, err = beans:connect()
    if err then
        throw("connect internal beanstalkd failed, %s", err)
    end
    return beans
end

function AddjobAction:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function AddjobAction:_newRedis()
    local redis = RedisService:create(self._cmd.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end
return AddjobAction
