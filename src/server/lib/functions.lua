
--[[

定义服务端公用函数

]]

-- 读取模块
function loadModel(model, redisId, redis)
    local properties, err = redis:command("hgetall", redisId)

    if err then
        throw(ERR_SERVER_REDIS_ERROR, err)
    end

    if not properties.id then
        properties.id = redisId
    end

    return model.new(properties)
end
