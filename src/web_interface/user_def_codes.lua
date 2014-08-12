
local config = require("server.config")

local function PullCode() 
    local repo = config.userDefinedCodes.local_repo

    local cmd = string.format("git pull %s", repo)
    ngx.say(cmd)
    local ok = string.popen(cmd) 
    if ok == 0 then 
        ngx.say("ok")
    else 
        ngx.say("error: " .. ok)
    end
end

PullCode()
