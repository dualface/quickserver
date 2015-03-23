
local tostring = tostring

local ConnectIdService = class("ConnectIdService")

ConnectIdService.CONNECTS_ID_DICT_KEY  = "_CONNECTS_ID_DICT" -- id => tag
ConnectIdService.CONNECTS_TAG_DICT_KEY = "_CONNECTS_TAG_DICT" -- tag => id

function ConnectIdService:ctor(redis)
    self._redis = redis
end

function ConnectIdService:getIdByTag(tag)
    if not tag then
        throw("get connect id by invalid tag \"%s\"", tostring(tag))
    end
    return self._redis:command("HGET", ConnectIdService.CONNECTS_TAG_DICT_KEY, tostring(tag))
end

function ConnectIdService:getTagById(connectId)
    if not connectId then
        throw("get connect tag by invalid id \"%s\"", tostring(connectId))
    end
    return self._redis:command("HGET", ConnectIdService.CONNECTS_ID_DICT_KEY, tostring(connectId))
end

function ConnectIdService:getTag(connectId)
    return self._redis:command("HGET", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId)
end

function ConnectIdService:setTag(connectId, tag)
    connectId = tostring(connectId)
    if not tag then
        throw("set connect \"%s\" tag with invalid tag", connectId)
    end
    local pipe = self._redis:newPipeline()
    pipe:command("HMSET", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId, tag)
    pipe:command("HMSET", ConnectIdService.CONNECTS_TAG_DICT_KEY, tag, connectId)
    pipe:commit()
end

function ConnectIdService:removeTag(connectId)
    local tag = self:getTag(connectId)
    if tag then
        local pipe = self._redis:newPipeline()
        pipe:command("HDEL", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId)
        pipe:command("HDEL", ConnectIdService.CONNECTS_TAG_DICT_KEY, tag)
        pipe:commit()
    end
end

return ConnectIdService
