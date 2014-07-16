-- require class framework
require("framework.functions")
require("framework.debug")

-- require mysql interface and config
local MysqlEasy = require("server.lib.MysqlEasy")
local config = require("server.config")
local dbname = config.mysql.database

echoInfo("---BEGIN---")

local function NewMysql()
    local mysql, err = MysqlEasy.new(config.mysql)

    if err then
        echoErr("failed to connect mysql, %s", err)
        return nil
    end

    return mysql
end

local mysql = NewMysql()
if not mysql then 
    return 
end

local function DumpRes(res, layer) 
    assert(type(res) == "table", "DumpRes(): param should be table")

    local repStr = string.rep("    ", layer)
    
    for k,v in pairs(res) do 
        local t = type(v)
        if t == "string" then 
            echoInfo("%s[%s] = \"%s\"", repStr, k, v)
        elseif t == "number" or t == "boolean" or t == nil then 
            echoInfo("%s[%s] = %s", repStr, k, v)
        else 
            echoInfo("%s[%s] = table_begin", repStr, k)
            DumpRes(v, layer+1)
            echoInfo("%s[%s] = table_end", repStr, k)
        end
    end
end

local function GetTableName(tbl) 
    assert(type(tbl) == "table", "GetTableName(): params should be table")

    local res = {}
    local tmp = "Tables_in_" .. dbname 

    for k, _ in ipairs(tbl) do 
        table.insert(res, tbl[k][tmp])
    end
    
    return res
end

local function CleanTable(tbl) 
    local sql = string.format("select entity_id from %s;", tbl)
    local res, err = mysql:query(sql)
    if not res then
        return err
    end

    for _, k in pairs(res) do 
        sql = string.format("select id from entity where id = '%s';", k.entity_id)
        res = mysql:query(sql)  -- don't care errors 
        if next(res) == nil then 
            sql = string.format("delete from %s where entity_id = '%s';", tbl, k.entity_id)
            echoInfo("sql = %s", sql)
            --mysql:query(sql)
        end
    end

    return nil
end

local function CleanIndexes()
    local res, err = mysql:query("select * from key1_index;")
    if not res then 
        echoError("mysql:query() failed: %s", err)
        return 
    end
    local tables = GetTableName(res)

    DumpRes(res, 0)
    --DumpRes(tables, 0)

    for _, k in ipairs(tables) do 
        if string.find(k, "_index$", 0) ~= nil then 
            err = CleanTable(k)
            if err then 
                echoError("Delete redundant item from index table %s failed: %s", k, err)
            end
        end
    end
end

CleanIndexes()
echoInfo("---DONE---")

