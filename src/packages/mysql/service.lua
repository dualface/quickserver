local MysqlService = class("MysqlService") 

function MysqlService:ctor(config)
    local adapter 
    if ngx then
        adapter = require("adapter.MysqlRestyAdapter")
    else
        adapter = require("adapter.MysqlLuaAdapter")
    end

    if not config or type(config) ~= "table" then 
        return nil, "config of mysql connections is nil."
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
