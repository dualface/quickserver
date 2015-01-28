--[[

Copyright (c) 2011-2015 chukong-inc.com

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
local tostring = tostring
local quoteSqlStr = ngx.quote_sql_str

local mysql = require("resty.mysql")

local MysqlRestyAdapter = class("MysqlRestyAdapter")

function MysqlRestyAdapter:ctor(config)
    self.db_ = nil
    local db, err = mysql:new()
    if not db then
        printWarn("MysqlRestyAdapter:ctor() - failed to instantiate mysql: %s", err)
        return db, err
    end

    self.db_ = db

    self.db_:set_timeout(config.timeout)

    local ok, err, errno, sqlstate = db:connect(config)
    if not ok then
        printWarn("MysqlRestyAdapter:ctor() - mysql connect error: %s, %s, %s", err, tostring(errno), sqlstate)
        return ok, err
    end

    self.config = config

    self.db_:query("SET NAMES 'utf8'")
end

function MysqlRestyAdapter:close()
    assert(self.db_ ~= nil, "Not connect to mysql")

    self.db_:close()
end

function MysqlRestyAdapter:setKeepAlive(timeout, size)
    assert(self.db_ ~= nil, "Not connect to mysql")
    
    self.db_:setKeepAlive(timeout, size)
end

function MysqlRestyAdapter:query(queryStr)
    assert(self.db_ ~= nil, "Not connect to mysql")

    local res, err, errno, sqlstate = self.db_:query(queryStr)

    if err then
        printWarn("MysqlRestyAdapter:query() - mysql query error: %s, %s, %s", err, tostring(errno), sqlstate)
    end

    return res, err
end

function MysqlRestyAdapter:escapeValue(value)
    return quoteSqlStr(value)
end

return MysqlRestyAdapter
