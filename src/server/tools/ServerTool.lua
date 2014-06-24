
local ServerTool = class("ServerTool", cc.server.ActionBase)

-- 清空数据库
function ServerTool:initdbAction(data)
    local help = function()
        print([[

REMOVE ALL DATAS IN DATABASE.

usage:
    tools server.initdb yes

]])
    end

    -- check arguments
    while help do
        if not data[1] or data[1] ~= "yes" then
            print("ERR: not specifies <yes>.")
            break
        end
        help = nil
    end

    if help then
        help()
        return false
    end

    local redis = self.app:getRedis()
    local script = [[
local count = 0
for _, key in ipairs(redis.call("keys", "*")) do
    count = count + 1
    redis.call("del", key)
end
return count]]

    print("----------------------------------------")
    local count, err = redis:command("eval", script, 0)
    print("----------------------------------------")
    if err then
        printf("ERR: %s\n", err)
        return false
    end

    printf("remove keys count: %d", toint(count))
    print("\ndone.\n")
    return true
end

return ServerTool
