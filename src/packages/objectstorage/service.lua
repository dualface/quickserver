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

local pairs = pairs
local ipairs =ipairs
local next = next
local sha1 = ngx.sha1_bin
local base64 = ngx.encode_base64
local table_insert = table.insert
local table_concat = table.concat
local string_gsub = string.gsub
local string_sub = string.sub
local string_lower = string.lower
local string_upper = string.upper
local string_format = string.format
local json_encode = json.encode
local json_decode = json.decode

local ObjectstorageService = class("ObjectstorageService")

local function constructParams_(rawData)
    local body = {}
    for _, t in pairs(rawData) do
        for k, v in pairs(t) do
                if k ~= "" then    -- ignore null name of property
                    body[k] = v
                end
        end
    end
    local id = base64(sha1(json_encode(body)))
    id = string_gsub(id, [[/]], [[-]])  -- delete "/" symbol
    local res = {id = string_sub(id, 1, -2), body = json_encode(body)}

    return res, body
end

function ObjectstorageService:ctor(app)
    local config = nil
    if app then
        config = app.config.mysql
    end
    self.mysql = cc.load("mysql").service.new(config)
    self.indexSql = require("packages.objectstorage.indexsql")
end

function ObjectstorageService:endService()
    self.mysql:close()
end

function ObjectstorageService:updateIndexes_(indexes, body, id)
    local indexSql = self.indexSql
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    -- create index tables
    local sharedIndexes = ngx.shared.INDEXES
    for _, p in pairs(indexes) do
        if sharedIndexes:get(p) == nil then
            local createIndexSql = indexSql.createIndex(p)
            local ok, err = mysql:query(createIndexSql)
            if not ok then
                return nil, err
            end
            sharedIndexes:set(p, 1)
        end
    end

    -- store and update index tables
    for k, v in pairs(body) do
        if sharedIndexes:get(k) == 1 then
            local tblName = k .. "_index"
            local p = {[k]=v, ["entity_id"]=id}
            local ok, err = mysql:insert(tblName, p)
            if not ok then
                return nil, err
            end
        end
    end

    return true, nil
end


-- not used, clean redundant items by cleaner.lua now
function ObjectstorageService:deleteIndexes_(body, id)
    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local sharedIndexes = ngx.shared.INDEXES
    for k in pairs(body) do
        if sharedIndexes:get(k) == 1 then
            local tblName = k .. "_index"
            local where = {entity_id = id}
            local ok, err = mysql:del(tblName, where)
            if not ok then
                return nil, err
            end
        end
    end

    return true, nil
end

function ObjectstorageService:findIndexes_(where)
    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local indexSql = self.indexSql
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local sql = indexSql.findIndex(where)
    local res, err = mysql:query(sql)
    if not res then
        return nil, err
    end

    return res, nil
end

function ObjectstorageService:handleInfos_(infos, rawData)
    for _, v in pairs(infos) do
        v = string_upper(v)
        if keywords[v] then
            local method = string_lower(v)
            local tmp = {}
            tmp[v] = self[method .. "_"](self)
            table_insert(rawData, tmp)
        end
    end
end

function ObjectstorageService:saveObj(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then
        return nil, "'rawData' is missed in param table."
    end

    local params, body = constructParams_(rawData)
    local ok, err = mysql:insert("entity", params)
    if not ok then
        return nil, err
    end

    -- begin to handle indexs
    local indexes = data.indexes or {}
    if infos ~= nil then
        for _, v in pairs(infos) do
            if keywords[v] then
                table_insert(indexes, string_upper(v))
            end
        end
    end
    if type(indexes) == "table" then
        ok, err = self:updateIndexes_(indexes, body, params.id)
        if not ok then
            return nil, err
        end
    end

    return params.id, nil
end

function ObjectstorageService:updateObj(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then
        return nil, "'rawdata' is missed in param table."
    end

    local id = data.id
    if id == nil or id == "" then
        return nil, "'id' is missed in param table."
    end

    local res, err = mysql:query("select * from entity where id='"..id.."';")
    if not res then
        return nil, err
    end
    if next(res) == nil then
        return "null", nil
    end

    local oriProperty = json_decode(res[1].body)
    local params, newProperty = constructParams_(rawData)
    for k,v in pairs(newProperty) do
        oriProperty[k] = v
    end
    params.body = json_encode(oriProperty)

    res, err = mysql:update("entity", params, {id=id})
    if not res then
        return nil, err
    end

    -- begin to handle indexs
    local indexes = data.indexes or {}
    if infos ~= nil then
        for _, v in pairs(infos) do
            if keywords[v] then
                table_insert(indexes, string_upper(v))
            end
        end
    end
    if type(indexes) == "table" then
        res, err = self:updateIndexes_(indexes, oriProperty, params.id)
        if not res then
            return nil, err
        end
    end

    return params.id, nil
end

function ObjectstorageService:deleteObj(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local id = data.id
    if id == nil or id == "" then
        return nil, "'id' is missed in param table."
    end

    local ok, err = mysql:del("entity", {id=id})
    if not ok then
        return nil, err
    end
    if ok.affected_rows == 0 then
        return "null", nil
    end

    return id, nil
end

function ObjectstorageService:findObj(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local id = data.id
    local property = data.property
    local res, err
    if id ~= nil then
        -- find by id
        if id == "" then
            return nil, "'id' is missed in param table."
        end

        res, err = mysql:query("select * from entity where id='"..id.."';")
        if not res then
            return nil, err
        end
        if next(res) == nil then
            return "null", nil
        end
    elseif property ~= nil then
        -- find by index
        if property == "" then
            return nil, "'property' is missed in param table."
        end

        local value = data.property_value
        if value == nil or value == "" then
            return nil, "'property_value' is missed in param table."
        end

        -- begin to handle index
        local where = {[property]=value}
        res, err = self:findIndexes_(where)
        if not res then
            return nil, err
        end
        if next(res) == nil then
            return "null", nil
        end

        local whereFields = {}
        for _, obj in ipairs(res) do
            local id = obj.entity_id
            whereFields[#whereFields+1] = "id='" .. id .. "'"
        end

        local sql = string_format("select * from entity where %s;", table_concat(whereFields, " OR "))

        res, err = mysql:query(sql)
        if not res then
            return nil, err
        end
        if next(res) == nil then
            return "null", nil
        end
    else
        return nil, "'id' and 'property' are missed in param table."
    end

    return res, nil
end

function ObjectstorageService:createIndex(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local indexSql = self.indexSql
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local property = data.property
    if property == nil or type(property) ~= "string" or property == "" then
        return nil, "'property' is missed in param table."
    end

    local createIndexSql = indexSql.createIndex(property)
    local ok, err = mysql:query(createIndexSql)
    if not ok then
        return nil, err
    end

    -- add new index to global shared memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, 1)

    return true, nil
end

function ObjectstorageService:deleteIndex(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local mysql = self.mysql
    if mysql == nil then
        return nil, "Service mysql is not initialized."
    end

    local indexSql = self.indexSql
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local property = data.property
    if property == nil or type(property) ~= "string" or property == "" then
        return nil, "'property' is missed in param table."
    end

    local dropIndexSql = indexSql.dropIndex(property)
    local ok, err = mysql:query(dropIndexSql)
    if not ok then
        return nil, err
    end

    -- delete index from global shard memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, nil)

    return true, nil
end

function ObjectstorageService:showIndex(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local sharedIndexes = ngx.shared.INDEXES
    if sharedIndexes == nil then
        return nil, "ngx_shared_dict 'INDEXES' is not created."
    end

    local keys = sharedIndexes:get_keys() -- return only the first 1024 indexes
    if keys ~= nil and next(keys) ~= nil then
       return keys, nil
    end

    return "null", nil
end

return ObjectstorageService
