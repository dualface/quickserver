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

local DropIndexSql = [[
DROP TABLE %s;
]]

local DeleteIndexSql = [[
]]

local FindIndexSql = [[
SELECT entity_id FROM %s WHERE %s = '%s';
]]

local InsertIndexSql = [[
INSERT INTO %s (%s,%s) VALUES (%s,%s);
]]

function CreateIndex(property)
    local tableName = property.."_index"
    local sql = fmt(CreateIndexSql, tableName, property, property)

    return sql
end

function DropIndex(property) 
    local tableName = property .. "_index"
    local sql = fmt(DropIndexSql, tableName) 

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

function InsertIndex(property, id, value)
    local tableName = property .. "_index"
    local sql = fmt(InsertIndexSql, tableName, "entity_id", property, id, value) 

    return sql
end

