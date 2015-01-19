local ServerTool = class("ServerTool")

function ServerTool:taillogAction(data)
    local cmd = string.format("tail -n %s ../nginx/logs/error.log", data[1])
    local p = assert(io.popen(cmd, "r"))

    local s = p:read("*a")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")

    printf("logs:\n\n%s", s)
end

return ServerTool
