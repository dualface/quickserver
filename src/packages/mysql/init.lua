local MysqlPackage = class("MysqlPackage") 

function MysqlPackage:ctor()
    self.service = import(".service")
end

return MysqlPackage 
