require("src.framework.functions")
local _config = require("conf.config")

local ipairs = ipairs
local io_popen = io.popen
local string_format = string.format   
local string_split = string.split 


local _pid = {}

local function _init()
    _config = _config.monitor or {
        process = {
            "nginx", 
            "redis", 
            "beanstalkd",
        },

        mem = {
            warning = 70,
            critical = 90,
        },

        cpu = {
            warning = 70,
            critical = 90,
        },

        interval = 10, 

        criticalStatePersistentTImes = 3, 
    }
end

local function _getPid()
    local process = _config.process
    for _, procName in ipairs(process) do
        local cmd = string_format("pgrep %s", procName)
        local fout = io_popen(cmd)
        local res = fout:read("*a")
        _pid[procName] = string_split(res, "\n")
        fout:close()
    end 
end

local function _monitor()
     
end

_monitor()
