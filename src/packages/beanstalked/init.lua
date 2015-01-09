local BeanstalkedPakcage = class("BeanstalkedPakcage")

function BeanstalkedPakcage:ctor()
    self.service = import(".service")
end

return BeanstalkedPakcage
