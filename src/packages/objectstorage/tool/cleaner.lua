--[[

Copyright (c) 2011-2015 chukong-inc.com

https://github.com/dualface/quickserver

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local assert = assert
local type = type
local pairs = pairs
local ipairs = ipairs
local next = next
local tblInsert = table.insert
local strFind = string.find
local strRep = string.rep
local strFormat = string.format
local strSub = string.sub

-- require class framework
require("framework.functions")
require("framework.debug")
local json = require("framework.json")

-- require mysql interface and config
local mysqlEasy = import(".MysqlEasy")
local config = require("server.config")
local dbname = config.mysql.database

printInfo("---BEGIN---")

local function newMysql()
    local mysql, err = mysqlEasy.new(config.mysql)

    if err then
        printError("failed to connect mysql, %s", err)
        return nil
    end

    return mysql
end

local mysql = newMysql()
if not mysql then
    return
end

local function dumpRes_(res, layer)
    assert(type(res) == "table", "dumpRes_(): param should be table")

    local repStr = strRep("    ", layer)

    for k,v in pairs(res) do
        local t = type(v)
        if t == "string" then
            printInfo("%s[%s] = \"%s\"", repStr, k, v)
        elseif t == "number" or t == "boolean" or t == nil then
            printInfo("%s[%s] = %s", repStr, k, v)
        else
            printInfo("%s[%s] = table_begin", repStr, k)
            dumpRes_(v, layer+1)
            printInfo("%s[%s] = table_end", repStr, k)
        end
    end
end

local function getTableName_(tbl)
    assert(type(tbl) == "table", "getTableName_(): params should be table")

    local res = {}
    local tmp = "Tables_in_" .. dbname

    for k, _ in ipairs(tbl) do
        tblInsert(res, tbl[k][tmp])
    end

    return res
end

local function cleanTable_(tbl)
    local sql = strFormat("select entity_id from %s;", tbl)
    local res, err = mysql:query(sql)
    if not res then
        return err
    end

    for _, k in pairs(res) do
        sql = strFormat("select id from entity where id = '%s';", k.entity_id)
        res = mysql:query(sql)  -- don't care errors
        if next(res) == nil then
            sql = strFormat("delete from %s where entity_id = '%s';", tbl, k.entity_id)
            printInfo("sql = %s", sql)
            mysql:query(sql)
        end
    end

    return nil
end

local function updateTable_(k, v, id)
    local tblName = k .. "_index"
    local sql = strFormat("select * from %s where entity_id = '%s';", tblName, id)
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

local function cleanIndexes()
    local res, err = mysql:query("show tables;")
    if not res then
        printError("mysql:query() failed: %s", err)
        return
    end
    local tables = getTableName_(res)
    local properties = {}  -- record indexed properties

    for _, k in ipairs(tables) do
        if strFind(k, "_index$", 0) ~= nil then
            err = cleanTable_(k)
            if err then
                printError("Delete redundant item from index table %s failed: %s", k, err)
            end
            properties[strSub(k, 1, -7)] = 1
        end
    end

    return properties
end

local function updateIndexes(properties)
    local res, err = mysql:query("select * from entity;")
    if not res then
        printError("mysql:query() failed: %s", err)
        return
    end

    for _, obj in pairs(res) do
        local tbl = json.decode(obj.body)
        for k, v in pairs(tbl) do
            if properties[k] then
                err = updateTable_(k, v, obj.id)
                if err then
                    printError("Update %s_index table failed: %s", k, err)
                end
            end
        end
    end
end

local properties = cleanIndexes()
updateIndexes(properties)

printInfo("---DONE---")

