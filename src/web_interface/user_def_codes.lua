local config = require("server.config")

local SHELL = "/home/cheeray/work/quick-x-server/src/web_interface/tool/deploy.sh"

local function PullCode(files)
    local repo = config.userDefinedCodes.localRepo
    local dest = config.userDefinedCodes.localDest
    if repo == nil or dest == nil then
        ngx.say("config 'localRepo' or 'localDest' missed")
    end

    local cmd = string.format("%s %s %s %s", SHELL, repo, dest, files)
    local ok = os.execute(cmd)
    if ok == 0 then
        ngx.say("ok")
    else
        ngx.say("error: " .. ok)
    end
end

local args = ngx.req.get_uri_args()

if args["files"] then
    local files = nil
    if type(args["files"]) == "table" then
        files = table.concat(args["files"], " ")
    else
        files = args["files"]
    end

    PullCode(files)
else
    ngx.say("param 'files' missed")
end
