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

local MysqlService = class("MysqlService")

local adapter
if ngx then
    adapter = import(".adapter.MysqlRestyAdapter")
else
    adapter = import(".adapter.MysqlLuaAdapter")
end

function MysqlService:ctor(config)
    if not config or type(config) ~= "table" then
        return nil, "config is invalid."
    end

    self.config = config
    self.mysql = adapter.new(config)
end

function MysqlService:close()
    local mysql = self.mysql
    if not mysql then
        return nil, "Package mysql is not initialized."
    end

    return mysql:close()
end

function MysqlService:query(queryStr)
    local mysql = self.mysql
    if not mysql then
        return nil, "Package mysql is no initialized."
    end

    return mysql:query(queryStr)
end

local _escapeValue = ngx.quote_sql_str

local function _escapeName(name)
    return string.format([[`%s`]], name)
end

function MysqlService:insert(tableName, params)
    local mysql = self.mysql
    if not mysql then
        return nil, "Package mysql is no initialized."
    end

    local fieldNames = {}
    local fieldValues = {}

    for name, value in pairs(params) do
        fieldNames[#fieldNames + 1] = _escapeName(name)
        fieldValues[#fieldValues + 1] = _escapeValue(value)
    end

    local sql = string.format("INSERT INTO %s (%s) VALUES (%s)",
                       _escapeName(tableName),
                       table.concat(fieldNames, ","),
                       table.concat(fieldValues, ","))

    return mysql:query(sql)
end

function MysqlService:update(tableName, params, where)
    local mysql = self.mysql
    if not mysql then
        return nil, "Package mysql is no initialized."
    end

    local fields = {}
    local whereFields = {}

    for name, value in pairs(params) do
        fields[#fields + 1] = _escapeName(name) .. "=".. _escapeValue(value)
    end

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = _escapeName(name) .. "=".. _escapeValue(value)
    end

    local sql = string.format("UPDATE %s SET %s %s",
                       _escapeName(tableName),
                       table.concat(fields, ","),
                       "WHERE " .. table.concat(whereFields, " AND "))

    return mysql:query(sql)
end

function MysqlService:del(tableName, where)
    local mysql = self.mysql
    if not mysql then
        return nil, "Package mysql is no initialized."
    end

    local whereFields = {}

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = _escapeName(name) .. "=".. _escapeValue(value)
    end

    local sql = string.format("DElETE FROM %s %s",
                       _escapeName(tableName),
                       "WHERE " .. table.concat(whereFields, " AND "))

    return mysql:query(sql)
end

return MysqlService
