-- require class framework
require("framework.functions")
require("framework.debug")
local json = require("framework.json")

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
            mysql:query(sql)
        end
    end

    return nil
end

local function UpdateTable(k, v, id)
    local tblName = k .. "_index"
    local sql = string.format("select * from %s where entity_id = '%s';", tblName, id)
    local res, err = mysql:query(sql) 
    if not res then
        return err
    end
    if next(res) ~= nil then
        return nil
    end

    local param = {[k] = v, entity_id = id}

    local err = nil 
    _, err = mysql:insert(tblName, param)

    return err
end

local function CleanIndexes()
    local res, err = mysql:query("show tables;")
    if not res then 
        echoError("mysql:query() failed: %s", err)
        return 
    end
    local tables = GetTableName(res)
    local properties = {}  -- record indexed properties

    for _, k in ipairs(tables) do 
        if string.find(k, "_index$", 0) ~= nil then 
            err = CleanTable(k)
            if err then 
                echoError("Delete redundant item from index table %s failed: %s", k, err)
            end
            properties[string.sub(k, 1, -7)] = 1
        end
    end

    return properties
end

local function UpdateIndexes(properties)
    local res, err = mysql:query("select * from entity;")
    if not res then 
        echoError("mysql:query() failed: %s", err)
        return 
    end

    for _, obj in pairs(res) do 
        local tbl = json.decode(obj.body)
        for k, v in pairs(tbl) do 
            if properties[k] then 
                err = UpdateTable(k, v, obj.id) 
                if err then 
                    echoError("Update %s_index table failed: %s", k, err)
                end
            end
        end 
    end
end

local properties = CleanIndexes()
UpdateIndexes(properties)

echoInfo("---DONE---")

