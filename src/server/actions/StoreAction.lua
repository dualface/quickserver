--[[
--REQ
    { 
        "action" : "actionname", 
        "rawdata": {
            { "key1" : "val1"}, 
            { "key2" : "val2", "index" : 1},
            ...
            {"key_n" : "val_n"}
        }

        ["id" : "xxxxxxx"]  --for delete/update operation
    }
--
--]]

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
                body[k] = v
        end
    end 
    local id = base64(sha1(json.encode(body)))

    return {id=id, body=json.encode(body)} 
end

local function IndexProperty() 

end

function StoreAction:ctor(app)
    self.super:ctor(app)

    self.Mysql = nil
    self.Redis = nil
    if app then 
        self.Mysql = app.getMysql(app)
        --self.Redis = self.app.getRedis(self.app)
    end

    self.indexSql = require(app.config.appModuleName.. "." .. app.config.actionPackage .. ".sql.IndexSql")

    self.OK = {success=1}
end

function StoreAction:SaveObjAction(data) 
    assert(type(data) == "table", "data is NOT a table!")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(rawdata) is missed.")
    end

    params = ConstructParams(rawData)
    local ok, err = mySql:insert("entity", params) 
    if not ok then 
        throw(ERR_SERVER_MYSQL_ERROR, "insert data failed: %s", err)
    end 

    self.OK.id = params.id
    return self.OK 
end 

function StoreAction:UpdateObjAction(data)
    assert(type(data) == "table", "data is NOT a table!")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local rawData = data.rawdata
    if rawData == nil or type(rawData) ~= "table" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(rawdata) is missed.")
    end

    local id = data.id
    if id == nil or type(id) ~= "string" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(id) is missed.")
    end

    params = ConstructParams(rawData)
    local ok, err = mySql:update("entity", params, {id=id}) 
    if not ok then 
        throw(ERR_SERVER_MYSQL_ERROR, "update data failed: %s", err)
    end 

    self.OK.id = params.id
    return self.OK
end

function StoreAction:DeleteObjAction(data)
    assert(type(data) == "table", "data is NOT a table!")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local id = data.id
    if id == nil or type(id) ~= "string" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(id) is missed.")
    end

    local ok, err = mySql:del("entity", {id=id}) 
    if not ok then 
        throw(ERR_SERVER_MYSQL_ERROR, "delete data failed: %s", err)
    end 

    self.OK.id = id
    return self.OK
end

function StoreAction:FindObjAction(data) 
    assert(type(data) == "table", "data is NOT a table!")

    local mySql = self.Mysql
    if mySql == nil then 
        throw(ERR_SERVER_MYSQL_ERROR, "connect to mysql failed.")
    end

    local id = data.id
    local property = data.property
    local res, err
    if id ~= nil then 
        -- find by id
        if type(id) ~= "string" then 
            throw(ERR_SERVER_INVALID_PARAMETERS, "param(id) is missed.")
        end

        res, err = mySql:query("select * from entity where id='"..id.."';")
        if not res then 
            throw(ERR_SERVER_MYSQL_ERROR, "query data failed: %s", err)
        end    
    elseif property ~= nil then 
        -- find by index
        local value = data.property_value
        if value == nil then 
            throw(ERR_SERVER_INVALID_PARAMETERS, "param(property_value) is missed.")
        end 

        local indexSql = self.indexSql 
        if indexSql == nil then
            throw(ERR_SERVER_UNKNOWN_ERROR, "IndexSql module is NOT loaded.")
        end

        local sql = indexSql.FindIndex{[property]=value}
        res, err = mySql:query(sql)
        if not res then 
            throw(ERR_SERVER_MYSQL_ERROR, "query data failed: %s", err)
        end 

        local id = res[1].entity_id
        res, err = mySql:query("select * from entity where id='"..id.."';")
        if not res then 
            throw(ERR_SERVER_MYSQL_ERROR, "query data failed: %s", err)
        end
    end

    self.OK.result = res
    return self.OK
end

function StoreAction:CreateIndexAction(data)
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
    if property == nil or type(property) ~= "string" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(prorperty) is missed.")
    end 

    local createIndexSql = indexSql.CreateIndex(property)
    local ok, err = mySql:query(createIndexSql)
    if not ok then
        throw(ERR_SERVER_MYSQL_ERROR, "create %s_index table failed: %s", property, err)
    end

    return self.OK
end

function StoreAction:DeleteIndexAction(data) 
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
    if property == nil or type(property) ~= "string" then 
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(property) is missed.")
    end

    local deleteIndexSql = indexSql.DeleteIndex(property)
    local ok, err = mySql:query(deleteIndexSql)
    if not ok then
        throw(ERR_SERVER_MYSQL_ERROR, "delete %s_index table failed: %s", property, err)
    end

    return self.OK
end

return StoreAction

