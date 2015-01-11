local ObjectstorageService = class("ObjectstorageService")

local keywords = {
    TIME = 1, 
    time = 1, 
    IP = 1, 
    ip = 1
}

local function _constructParams(rawData)
    local sha1_bin
    local bas64
    if ngx then 
        sha1 = ngx.sha1_bin
        base64 = ngx.encode_base64
    else 
        throw(ERR_SERVER_UNKNOWN_ERROR, "ngx is nil")
    end

    local body = {}
    for _, t in pairs(rawData) do 
        for k, v in pairs(t) do
                if k ~= "" then    -- ignore null name of property 
                    body[k] = v
                end
        end
    end 
    local id = base64(sha1(json.encode(body)))
    id = string.gsub(id, [[/]], [[-]])  -- delete "/" symbol
    local res = {id = string.sub(id, 1, -2), body = json.encode(body)}

    return res, body 
end

function ObjectstorageService:ctor(app)
    local config = nil
    if app then
        config = app.config.mysql
    end
    self.mysql = cc.load("mysql").service.new(config)
    self.mysql:connect()
    self.indexSql = require("packages.objectstorage._indexsql")
end

function ObjectstorageService:endService()
    self.mysql:close()
end

function ObjectstorageService:_updateIndexes(indexes, body, id)
    local indexSql = self.indexSql
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local mySql = self.Mysql
    if mySql == nil then 
        return nil, "Service mysql is not initialized."
    end

    -- create index tables
    local sharedIndexes = ngx.shared.INDEXES
    for _, p in pairs(indexes) do 
        if sharedIndexes:get(p) == nil then 
            local createIndexSql = indexSql.CreateIndex(p)
            local ok, err = mySql:query(createIndexSql)
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
            local ok, err = mySql:insert(tblName, p)
            if not ok then 
                return nil, err
            end
        end
    end

    return true, nil
end 


-- not used, clean redundant items by cleaner.lua now
function ObjectstorageService:_deleteIndexes(body, id) 
    local mySql = self.Mysql
    if mySql == nil then 
        return nil, "Service mysql is not initialized."
    end

    local sharedIndexes = ngx.shared.INDEXES
    for k in pairs(body) do 
        if sharedIndexes:get(k) == 1 then 
            local tblName = k .. "_index"
            local where = {entity_id = id}
            local ok, err = mySql:del(tblName, where)
            if not ok then 
                return nil, err
            end
        end
    end

    return true, nil
end

function ObjectstorageService:_findIndexes(where)
    local mySql = self.Mysql
    if mySql == nil then 
        return nil, "Service mysql is not initialized." 
    end

    local indexSql = self.indexSql 
    if indexSql == nil then
        return nil, "Service objectstorage is not initialized."
    end

    local sql = indexSql.FindIndex(where)
    local res, err = mySql:query(sql)
    if not res then 
        return nil, err
    end 

    return res, nil
end

function ObjectstorageService:_TIME()
    return ngx.localtime()
end

function ObjectstorageService:_IP()
    return ngx.var.remote_addr 
end

function ObjectstorageService:_handleInfos(infos, rawData)
    for _, v in pairs(infos) do 
        if keywords[v] then 
            local method = string.upper(v)
            local tmp = {}
            tmp[method] = self["_"..method](self) 
            table.insert(rawData, tmp)
        end 
    end
end

function ObjectstorageService:Saveobj(data) 
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
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

        self:_handleInfos(infos, rawData)
    end

    local params, body = _constructParams(rawData)
    local ok, err = mySql:insert("entity", params) 
    if not ok then 
        return nil, err
    end 

    -- begin to handle indexs
    local indexes = data.indexes or {} 
    if infos ~= nil then 
        for _, v in pairs(infos) do
            if keywords[v] then 
                table.insert(indexes, string.upper(v))
            end
        end
    end
    if type(indexes) == "table" then 
        ok, err = self:_updateIndexes(indexes, body, params.id)
        if not ok then 
            return nil, err
        end
    end

    return params.id, nil
end 

function ObjectstorageService:Updateobj(data)
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
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

    local res, err = mySql:query("select * from entity where id='"..id.."';")
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

        self:_handleInfos(infos, rawData)
    end

    local oriProperty = json.decode(res[1].body)
    local params, newProperty = _constructParams(rawData)
    for k,v in pairs(newProperty) do 
        oriProperty[k] = v 
    end 
    params.body = json.encode(oriProperty) 
    
    res, err = mySql:update("entity", params, {id=id}) 
    if not res then 
        return nil, err
    end 

    -- begin to handle indexs
    local indexes = data.indexes or {} 
    if infos ~= nil then
        for _, v in pairs(infos) do
            if keywords[v] then 
                table.insert(indexes, string.upper(v))
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

function ObjectstorageService:Deleteobj(data)
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
        return nil, "Service mysql is not initialized."
    end

    local id = data.id
    if id == nil or id == "" then 
        return nil, "'id' is missed in param table."
    end

    local ok, err = mySql:del("entity", {id=id}) 
    if not ok then 
        return nil, err
    end 
    if ok.affected_rows == 0 then 
        return "null", nil
    end

    return id, nil
end

function ObjectstorageService:Findobj(data) 
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
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

        res, err = mySql:query("select * from entity where id='"..id.."';")
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
        res, err = self:_findIndexes(where)
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

        local sql = string.format("select * from entity where %s;", table.concat(whereFields, " OR "))  

        res, err = mySql:query(sql)
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

function ObjectstorageService:Createindex(data)
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
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

    local createIndexSql = indexSql.CreateIndex(property)
    local ok, err = mySql:query(createIndexSql)
    if not ok then
        return nil, err
    end

    -- add new index to global shared memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, 1)

    return true, nil 
end

function ObjectstorageService:Deleteindex(data) 
    if type(data) ~= "table" then 
        return nil, "Parameter is not a table."
    end

    local mySql = self.Mysql
    if mySql == nil then 
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

    local dropIndexSql = indexSql.DropIndex(property)
    local ok, err = mySql:query(dropIndexSql)
    if not ok then
        return nil, err
    end

    -- delete index from global shard memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, nil)

    return true, nil
end

function ObjectstorageService:Showindex(data)
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
