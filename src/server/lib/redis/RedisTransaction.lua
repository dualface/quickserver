
local RedisTransaction = class("RedisTransaction")

function RedisTransaction:ctor(easy, ...)
    self.easy = easy
    self.commandsCount = 0
    if #{...} > 0 then self:watch(...) end
end

function RedisTransaction:watch(...)
    assert(self.commandsCount == 0, "RedisTransaction:watch() - WATCH inside MULTI is not allowed")
    return self.easy:command("watch", ...)
end

function RedisTransaction:command(command, ...)
    if self.commandsCount == 0 then
        self.easy:command("multi")
    end
    self.commandsCount = self.commandsCount + 1
    return self.easy:command(command, ...)
end

function RedisTransaction:commit()
    if self.commandsCount == 0 then return true end
    return self.easy:command("exec")
end

function RedisTransaction:discard()
    if self.commandsCount == 0 then return true end
    return self.easy:command("discard")
end

return RedisTransaction
