
local mysql = require "luasql.mysql"

local MysqlLuaAdapter = class("MysqlLuaAdapter")

function MysqlLuaAdapter:ctor(config)
    self.db_   = nil
    self.env_ = nil

    local env, err = mysql.mysql()

    if err then
        printf("[MYSQL] failed to instantiate mysql: %s", err)
        return db, err
    end

    self.env_ = env

    local con, err = self.env_:connect(config.database, config.user, config.password, config.host, config.port)
    self.db_ = con

    self.db_:execute"SET NAMES 'utf8'"
end

function MysqlLuaAdapter:close()
    assert(self.db_ ~= nil, "Not connect to mysql")

    self.db_:close()
    self.env_:close()
end

function MysqlLuaAdapter:query(queryStr)
    assert(self.db_ ~= nil, "Not connect to mysql")

    local cur, err = self.db_:execute(queryStr)

    if err then
        printf("[MYSQL] failed to query mysql: %s", err)
        return cur, err
    end

    if type(cur) == "userdata" then
        if cur:numrows() == 0 then
            return {}, err
        end

        local row, err = cur:fetch ({}, "a")

        if err then
            printf("[MYSQL] failed to query mysql: %s", err)
            return row, err
        end

        local results = {}
        local result = {}
        for key, value in pairs(row) do 
            result[key] = value
        end
        results[#results+1] = result

        while true do
            row = cur:fetch (row, "a")

            if row == nil then
                break
            end

            result = {} 
            for key, value in pairs(row) do
                result[key] = value
            end

            results[#results + 1] = result
        end

        return results, err
    end

    return cur, err
end


function MysqlLuaAdapter:escapeValue(value)
    assert(self.db_ ~= nil, "Not connect to mysql")

    return string.format("'%s'", self.db_:escape(value))
end

return MysqlLuaAdapter
