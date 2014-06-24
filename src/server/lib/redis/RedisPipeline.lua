
local RedisPipeline = class("RedisPipeline")

function RedisPipeline:ctor(easy)
    self.easy = easy
    self.commandsCount = 0
    self.commands = {}
end

function RedisPipeline:command(command, ...)
    self.commandsCount = self.commandsCount + 1
    self.commands[#self.commands + 1] = {command, {...}}
end

function RedisPipeline:commit()
    if self.commandsCount > 0 then
        return self.easy.adapter:commitPipeline(self.commands)
    else
        return {}
    end
end

return RedisPipeline
