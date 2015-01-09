local RedisPackage = class("RedisPackage")

function RedisPackage:ctor()
    self.service = import(".service")
end

return RedisPackage 
