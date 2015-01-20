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

local type = type
local pairs = pairs
local tostring = tostring
local strFormat = string.format
local tblConcat = table.concat

local MysqlEasy = class("MysqlEasy")

local MysqlAdapter
MysqlAdapter = import(".MysqlLuaAdapter")

function MysqlEasy:ctor(config)
    self.db_ = nil
    local db, err = MysqlAdapter.new(config)
    if not db then
        printf("[MYSQL] failed to instantiate mysql: %s", err)
        return db, err
    end

    self.db_ = db
end

function MysqlEasy:close()
    assert(self.db_ ~= nil, "Not connect to mysql")
    self.db_:close()
end

function MysqlEasy:query(queryStr)
    assert(self.db_ ~= nil, "Not connect to mysql")

    local ok, err = self.db_:query(queryStr)
    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end

    return ok, err
end

function MysqlEasy:insert(tableName, params)
    assert(self.db_ ~= nil, "Not connect to mysql")
    local fieldNames = {}
    local fieldValues = {}

    for name, value in pairs(params) do
        fieldNames[#fieldNames + 1] = self:escapeName(name)
        fieldValues[#fieldValues + 1] = self:escapeValue(value)
    end

    local sql = strFormat("INSERT INTO %s (%s) VALUES (%s)",
                       self:escapeName(tableName),
                       tblConcat(fieldNames, ","),
                       tblConcat(fieldValues, ","))

    -- printf("SQL: " .. sql)
    local ok, err = self.db_:query(sql)
    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end
    return ok, err
end

function MysqlEasy:update(tableName, params, where)
    assert(self.db_ ~= nil, "Not connect to mysql")
    local fields = {}
    local whereFields = {}

    for name, value in pairs(params) do
        fields[#fields + 1] = self:escapeName(name) .. "=".. self:escapeValue(value)
    end

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = self:escapeName(name) .. "=".. self:escapeValue(value)
    end

    local sql = strFormat("UPDATE %s SET %s %s",
                       self:escapeName(tableName),
                       tblConcat(fields, ","),
                       "WHERE " .. tblConcat(whereFields, " AND "))

    -- printf("SQL: " .. sql)

    local ok, err = self.db_:query(sql)
    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end
    return ok, err
end

function MysqlEasy:del(tableName, where)
    assert(self.db_ ~= nil, "Not connect to mysql")
    local whereFields = {}

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = self:escapeName(name) .. "=".. self:escapeValue(value)
    end

    local sql = strFormat("DElETE FROM %s %s",
                       self:escapeName(tableName),
                       "WHERE " .. tblConcat(whereFields, " AND "))

    -- printf("SQL: " .. sql)

    local ok, err = self.db_:query(sql)
    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end

    return ok, err
end

function MysqlEasy:escapeName(name)
    return strFormat("`%s`", name)
end

function MysqlEasy:escapeValue(value)
    assert(self.db_ ~= nil, "Not connect to mysql")

    return self.db_:escapeValue(value)
end

return MysqlEasy
