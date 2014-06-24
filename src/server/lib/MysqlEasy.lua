
local MysqlEasy = class("MysqlEasy")

local MysqlAdapter
if ngx and ngx.log then
    MysqlAdapter = import(".mysql.MysqlRestyAdapter")
else
    MysqlAdapter = import(".mysql.MysqlLuaAdapter")
end

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

    local sql = string.format("INSERT INTO %s (%s) VALUES (%s)",
                       self:escapeName(tableName),
                       table.concat(fieldNames, ","),
                       table.concat(fieldValues, ","))

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

    local sql = string.format("UPDATE %s SET %s %s",
                       self:escapeName(tableName),
                       table.concat(fields, ","),
                       "WHERE " .. table.concat(whereFields, " AND "))

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

    local sql = string.format("DElETE FROM %s %s",
                       self:escapeName(tableName),
                       "WHERE " .. table.concat(whereFields, " AND "))

    -- printf("SQL: " .. sql)

    local ok, err = self.db_:query(sql)
    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end

    return ok, err
end

function MysqlEasy:escapeName(name)
    return string.format("`%s`", name)
end

function MysqlEasy:escapeValue(value)
    assert(self.db_ ~= nil, "Not connect to mysql")

    return self.db_:escapeValue(value)
end

return MysqlEasy
