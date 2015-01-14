local TestWorker = class("TestWorker")

function TestWorker:sayhelloAction(data)
    return {hello = data.k}
end

return TestWorker
