local base = cc.load("objectstorage").action

local TestWorker = class("TestWorker", base)

function TestWorker:ctor(app)
    self.super:ctor(app)
end

return TestWorker
