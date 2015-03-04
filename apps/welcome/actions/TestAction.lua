local TestAction = class("TestAction")

function TestAction:ctor(connect)
    self.connect = connect
end

function TestAction:loopAction(arg)
    local count = arg.count

    local i = 0
    while true do
        i = i + 1
        if i == count * 1000000000 then
            break
        end
    end
end

function TestAction:echoAction(arg)
    local t = {}

    for k, v in pairs(arg) do
        t[k] = v
    end

    return t
end

return TestAction
