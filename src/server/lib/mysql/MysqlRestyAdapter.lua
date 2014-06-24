
local mysql = require("resty.mysql")

local MysqlRestyAdapter = class("MysqlRestyAdapter")

function MysqlRestyAdapter:ctor(config)
    self.db_ = nil
    local db, err = mysql:new()
    if not db then
        printf("[MYSQL] failed to instantiate mysql: %s", err)
        return db, err
    end

    self.db_ = db

    self.db_:set_timeout(config.timeout)

    local ok, err, errno, sqlstate = db:connect(config)
    if not ok then
        printf("[MYSQL] mysql connect error: %s, %s, %s", err, tostring(errno), sqlstate)
        return ok, err
    end

    self.db_:query("SET NAMES 'utf8'")
end

function MysqlRestyAdapter:close()
    assert(self.db_ ~= nil, "Not connect to mysql")

    self.db_:close()
end

function MysqlRestyAdapter:query(queryStr)
    assert(self.db_ ~= nil, "Not connect to mysql")

    local res, err, errno, sqlstate = self.db_:query(queryStr)

    if err then
        printf("[MYSQL] mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end

    return res, err
end

function MysqlRestyAdapter:escapeValue(value)
    return ngx.quote_sql_str(value)
end

return MysqlRestyAdapter