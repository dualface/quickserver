local fmt = string.format
local type = type
local assert = assert
local pairs = pairs
module(...)

local CreateIndexSql = [[ 
CREATE TABLE IF NOT EXISTS %s (
    entity_id VARCHAR(32) NOT NULL UNIQUE,
    %s VARCHAR(512) NOT NULL, 
    PRIMARY KEY(%s, entity_id)
) ENGINE=InnoDB; ]]

local DeleteIndexSql = [[
DROP TABLE %s;
]]

local FindIndexSql = [[
SELECT entity_id from %s where %s = '%s';
]]

function CreateIndex(property)
    local tableName = property.."_index"
    local sql = fmt(CreateIndexSql, tableName, property, property)

    return sql
end

function DeleteIndex(property) 
    local tableName = property .. "_index"
    local sql = fmt(DeleteIndexSql, tableName) 

    return sql
end

function FindIndex(propertyTbl) 
    assert(type(propertyTbl) == "table", "param in FindIdSql() is NOT a table.")

    local n = pairs(propertyTbl)
    local k, v = n(propertyTbl) 
    local tableName = k .. "_index"
    local sql = fmt(FindIndexSql, tableName, k, v)

    return sql
end

