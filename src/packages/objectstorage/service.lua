local sha1 = ngx.sha1_bin
local base64 = ngx.encode_base64
local remoteAddr = ngx.var.remote_addr
local localtime = ngx.localtime
local tabInsert = table.insert
local tabConcat = table.concat
local strGsub = string.gsub 
local strSub = string.sub
local strLower = string.lower
local strUpper = string.upper
local strFormat = string.format
local jsonEncode = json.encode
local jsonDecode = json.decode

local keywords = {
    TIME = 1, 
    IP = 1, 
}

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
    local id = base64(sha1(jsonEncode(body)))
    id = strGsub(id, [[/]], [[-]])  -- delete "/" symbol
    local res = {id = strSub(id, 1, -2), body = jsonEncode(body)}

    return res, body 
end

function ObjectstorageService:ctor(app)
    local config = nil
    if app then
        config = app.config.mysql
    end
    self.mysql = cc.load("mysql").service.new(config)
    self.mysql:connect()
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

function ObjectstorageService:time_()
    return localtime()
end

function ObjectstorageService:ip_()
    return remoteAddr 
end

function ObjectstorageService:handleInfos_(infos, rawData)
    for _, v in pairs(infos) do 
        v = strUpper(v)
        if keywords[v] then 
            local method = strLower(v)
            local tmp = {}
            tmp[v] = self[method .. "_"](self) 
            tabInsert(rawData, tmp)
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

    -- handle addtional_info, such as "IP" and "TIME"
    local infos = data.addtional_info 
    if infos ~= nil then
        if type(infos) ~= "table" then 
            return nil, "'addtional_info' is not an array."
        end

        self:handleInfos_(infos, rawData)
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
                tabInsert(indexes, strUpper(v))
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

    -- handle addtional_info, such as "IP" and "TIME"
    local infos = data.addtional_info 
    if infos ~= nil then
        if type(infos) ~= "table" then 
            return nil, "'addtional_info' is not an array."
        end

        self:handleInfos_(infos, rawData)
    end

    local oriProperty = jsonDecode(res[1].body)
    local params, newProperty = constructParams_(rawData)
    for k,v in pairs(newProperty) do 
        oriProperty[k] = v 
    end 
    params.body = jsonEncode(oriProperty) 
    
    res, err = mysql:update("entity", params, {id=id}) 
    if not res then 
        return nil, err
    end 

    -- begin to handle indexs
    local indexes = data.indexes or {} 
    if infos ~= nil then
        for _, v in pairs(infos) do
            if keywords[v] then 
                tabInsert(indexes, strUpper(v))
            end
        end
    end
    if type(indexes) == "table" then 
        res, err = self:_updateIndexes(indexes, oriProperty, params.id)
        if not res then 
            return nil, err
        end
    end

    return param.id, nil
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

        local sql = strFormat("select * from entity where %s;", tabConcat(whereFields, " OR "))  

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

function ObjectstorageService:createindex(data)
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
        throw(ERR_SERVER_UNKNOWN_ERROR, "shared INDEXES is nil.")
        return nil, "ngx_shared_dict 'INDEXES' is not created." 
    end

    local keys = sharedIndexes:get_keys() -- return only the first 1024 indexes
    if keys ~= nil and next(keys) ~= nil then
       return keys, nil
    end

    return "null", nil 
end

return ObjectstorageService
