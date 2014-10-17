--[[
--REQ
    { 
        "action" : "actionname", 
        "rawdata": {
            { "key1" : "val1"}, 
            { "key2" : "val2"},
            ...
            {"key_n" : "val_n"}
        }

        "id" : "xxxxxxx"  --for delete/update/find operation
        "indexs": [key1, key3, ...] -- keys, which need index
        "addtional_info": ["IP", "TIME"] 
    }
--
--]]

local ERR_STORE_INVALID_PARAM = 2000
local ERR_STORE_OPERATION_FAILED = 2100

-- keywords dictionary
local keywords = {
    TIME = 1, 
    time = 1, 
    IP = 1, 
    ip = 1
}

local StoreAction = class("StoreAction", cc.server.ActionBase)

local function ConstructParams(rawData)
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

local function Err(errCode, errMsg, ...) 
   local msg = string.format(errMsg, ...)

   return {err_code=errCode, err_msg=msg} 
end

function StoreAction:ctor(app)
    self.super:ctor(app)

    if app then 
        self.Mysql = app.getMysql(app)
    end

    self.indexSql = require(app.config.appModuleName.. "." .. app.config.actionPackage .. ".sql.IndexSql")

    self.reply = {}
end

function StoreAction:_UpdateIndexes(indexes, body, id)
    local indexSql = self.indexSql
    if indexSql == nil then
        -- just use echoinfo to handle writting index, the same below 
        echoInfo("IndexSql module is NOT loaded.")
        return ERR_STORE_OPERATION_FAILED 
    end

    local mySql = self.Mysql
    if mySql == nil then 
        echoInfo("connect to mysql failed.")
        return ERR_STORE_OPERATION_FAILED
    end

    -- create index tables
    local sharedIndexes = ngx.shared.INDEXES
    for _, p in pairs(indexes) do 
        if sharedIndexes:get(p) == nil then 
            local createIndexSql = indexSql.CreateIndex(p)
            local ok, err = mySql:query(createIndexSql)
            if not ok then
                echoInfo("create %s_index table failed: %s", property, err)
                return ERR_STORE_OPERATION_FAILED
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
                echoInfo("update index table %s failed: %s", tblName, err)
                return ERR_STORE_OPERATION_FAILED
            end
        end
    end

    return nil
end 


-- not used, clean redundant items by cleaner.lua now
function StoreAction:_DeleteIndexes(body, id) 
    local mySql = self.Mysql
    if mySql == nil then 
        echoInfo("connect to mysql failed.")
        return ERR_STORE_OPERATION_FAILED
    end

    local sharedIndexes = ngx.shared.INDEXES
    for k in pairs(body) do 
        if sharedIndexes:get(k) == 1 then 
            local tblName = k .. "_index"
            local where = {entity_id = id}
            local ok, err = mySql:del(tblName, where)
            if not ok then 
                echoInfo("delete index table %s failed: %s", tblName, err)
                return ERR_STORE_OPERATION_FAILED
            end
        end
    end

    return nil
end

function StoreAction:_FindIndexes(where)
    local mySql = self.Mysql
    if mySql == nil then 
        echoError("connect to mysql failed.")
        return nil
    end

    local indexSql = self.indexSql 
    if indexSql == nil then
        -- in reading from index, use echoError
        echoError("IndexSql module is NOT loaded.")
        return nil
    end

    local sql = indexSql.FindIndex(where)
    local res, err = mySql:query(sql)
    if not res then 
        echoError("find index table, sql: %s failed: %s", sql, err)
        return nil 
    end 

    return res
end

function StoreAction:_TIME()
    return ngx.localtime()
end

function StoreAction:_IP()
    return ngx.var.remote_addr 
end

function StoreAction:_HandleInfos(infos, rawData)
    for _, v in pairs(infos) do 
        if keywords[v] then 
            local method = string.upper(v)
            local tmp = {}
            tmp[method] = self["_"..method](self) 
            table.insert(rawData, tmp)
        end 
    end
end

function StoreAction:SaveobjAction(data) 
    assert(type(data) == "table", "data is NOT a table")

    echoInfo("remote_addr = %s", ngx.var.remote_addr)

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(rawdata) is missed")
        return self.reply
    end

    -- handle addtional_info, such as "IP" and "TIME"
    local infos = data.addtional_info 
    if infos ~= nil then
        if type(infos) ~= "table" then 
            self.reply = Err(ERR_STORE_INVALID_PARAM, "param(addtional_info) is NOT an array")
            return self.reply
        end

        local err = self:_HandleInfos(infos, rawData)
        if err then 
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.SaveObj failed: handle addtional_info failed.")
            return self.reply
        end
    end

    local params, body = ConstructParams(rawData)
    local ok, err = mySql:insert("entity", params) 
    if not ok then 
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.SaveObj failed: %s", err)
        return self.reply
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
        err = self:_UpdateIndexes(indexes, body, params.id)
        if err then 
            echoInfo("operation Store.SaveObj success, but update index tables failed.")
        end
    end

    self.reply.id = params.id
    return self.reply 
end 

function StoreAction:UpdateobjAction(data)
    assert(type(data) == "table", "data is NOT a table")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(rawdata) is missed")
        return self.reply
    end

    local id = data.id
    if id == nil or id == "" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local res, err = mySql:query("select * from entity where id='"..id.."';")
    if not res then 
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.UpdateObj failed: %s", err)
        return self.reply
    end
    if next(res) == nil then 
        return self.reply
    end

    -- handle addtional_info, such as "IP" and "TIME"
    local infos = data.addtional_info 
    if infos ~= nil then
        if type(infos) ~= "table" then 
            self.reply = Err(ERR_STORE_INVALID_PARAM, "param(addtional_info) is NOT an array")
            return self.reply
        end

        local err = self:_HandleInfos(infos, rawData)
        if err then 
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.UpdateObj failed: handle addtional_info failed.")
            return self.reply
        end
    end

    local oriProperty = json.decode(res[1].body)
    local params, newProperty = ConstructParams(rawData)
    for k,v in pairs(newProperty) do 
        oriProperty[k] = v 
    end 
    params.body = json.encode(oriProperty) 
    
    res, err = mySql:update("entity", params, {id=id}) 
    if not res then 
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.UpdateObj failed: %s", err)
        return self.reply
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
        err = self:_UpdateIndexes(indexes, oriProperty, params.id)
        if err then 
            echoInfo("operation Store.SaveObj success, but update index tables failed.")
        end
    end

    self.reply.id = params.id -- after update, id is also changed.
    return self.reply
end

function StoreAction:DeleteobjAction(data)
    assert(type(data) == "table", "data is NOT a table")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local id = data.id
    if id == nil or id == "" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(id) is missed")
        return self.reply
    end

    local ok, err = mySql:del("entity", {id=id}) 
    if not ok then 
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.DeleteObj failed: %s", err)
        return self.reply
    end 
    if ok.affected_rows == 0 then 
        return self.reply
    else 
    end

    self.reply.id = id
    return self.reply
end

function StoreAction:FindobjAction(data) 
    assert(type(data) == "table", "data is NOT a table")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local id = data.id
    local property = data.property
    local res, err
    if id ~= nil then 
        -- find by id
        if id == "" then 
            self.reply = Err(ERR_STORE_INVALID_PARAM, "param(id) is missed")
            return self.reply
        end

        res, err = mySql:query("select * from entity where id='"..id.."';")
        if not res then 
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.FindObj failed: %s", err)
            return self.reply
        end    
        if next(res) == nil then 
            return self.reply
        end

    elseif property ~= nil then 
        -- find by index
        if property == "" then 
            self.reply = Err(ERR_STORE_INVALID_PARAM, "param(property) is missed")
            return self.reply
        end

        local value = data.property_value
        if value == nil or value == "" then 
            self.reply = Err(ERR_STORE_INVALID_PARAM, "param(property_value) is missed")
            return self.reply
        end 

        -- begin to handle index
        local where = {[property]=value}
        res, err = self:_FindIndexes(where)
        if not res then 
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.FindObj failed: can't find object via this property '%s'", property)
            return self.reply
        end
        if next(res) == nil then 
            return self.reply
        end

        local whereFields = {}
        for _, obj in ipairs(res) do 
            local id = obj.entity_id
            whereFields[#whereFields+1] = "id='" .. id .. "'"
        end

        local sql = string.format("select * from entity where %s;", table.concat(whereFields, " OR "))  
        echoInfo("sql = %s", sql)

        res, err = mySql:query(sql)
        if not res then
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.FindObj failed: %s", err)
            return self.reply
        end
        if next(res) == nil then 
            return self.reply
        end
    else 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "both 'id' and 'property' are missed")        
        return self.reply
    end

    self.reply.objs = res
    return self.reply
end

function StoreAction:CreateindexAction(data)
    assert(type(data) == "table", "data is NOT a table.")

    local indexSql = self.indexSql
    if indexSql == nil then
        throw(ERR_SERVER_UNKNOWN_ERROR, "IndexSql module is NOT loaded.")
    end

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local property = data.property
    if property == nil or type(property) ~= "string" or property == "" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(property) is missed")
        return self.reply
    end 

    local createIndexSql = indexSql.CreateIndex(property)
    local ok, err = mySql:query(createIndexSql)
    if not ok then
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.CreateIndex for property '%s' failed: %s", property, err)
        return self.reply
    end

    -- add new index to global shared memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, 1)

    return self.reply
end

function StoreAction:DeleteindexAction(data) 
    assert(type(data) == "table", "data is NOT a table.")

    local indexSql = self.indexSql
    if indexSql == nil then
        throw(ERR_SERVER_UNKNOWN_ERROR, "IndexSql module is NOT loaded.")
    end

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end
    
    local property = data.property
    if property == nil or type(property) ~= "string" or property == "" then 
        self.reply = Err(ERR_STORE_INVALID_PARAM, "param(property) is missed")
        return self.reply
    end

    local dropIndexSql = indexSql.DropIndex(property)
    local ok, err = mySql:query(dropIndexSql)
    if not ok then
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.DeleteIndex for property %s failed: %s", property, err)
        return self.reply
    end

    -- delete index from global shard memory
    local sharedIndexes = ngx.shared.INDEXES
    sharedIndexes:set(property, nil)

    return self.reply
end

function StoreAction:ShowindexAction(data)
    assert(type(data) == "table", "data is NOT a table.")

    local sharedIndexes = ngx.shared.INDEXES
    if sharedIndexes == nil then 
        throw(ERR_SERVER_UNKNOWN_ERROR, "shared INDEXES is nil.")
    end

    local keys = sharedIndexes:get_keys() -- retur only the first 1024 indexes
    if keys ~= nil and next(keys) ~= nil then
       self.reply.keys = keys
    end

    return self.reply
end

return StoreAction

