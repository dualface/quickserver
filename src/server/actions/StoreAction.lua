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

        "id" : "xxxxxxx"  --for delete/update/find operation
    }
--
--]]

local ERR_STORE_INVALID_PARAM = 2000
local ERR_STORE_OPERATION_FAILED = 2100

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
                if k ~= "index" and k ~= "" then    -- ignore null name of property 
                    body[k] = v
                else 

                end
        end
    end 
    local id = base64(sha1(json.encode(body)))
    local res = {id = string.sub(id, 1, -2), body = json.encode(body)}

    return res, body 
end

local function Err(errCode, errMsg, ...) 
   local msg = string.format(errMsg, ...)

   return {err_code=errCode, err_msg=msg} 
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

    self.reply = {}
end

function StoreAction:SaveObjAction(data) 
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

    local params = ConstructParams(rawData)
    local ok, err = mySql:insert("entity", params) 
    if not ok then 
        self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.SaveObj failed: %s", err)
        return self.reply
    end 

    self.reply.id = params.id
    return self.reply 
end 

function StoreAction:UpdateObjAction(data)
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

    self.reply.id = params.id -- after update, id is also changed.
    return self.reply
end

function StoreAction:DeleteObjAction(data)
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
    end

    self.reply.id = id
    return self.reply
end

function StoreAction:FindObjAction(data) 
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

        local indexSql = self.indexSql 
        if indexSql == nil then
            throw(ERR_SERVER_UNKNOWN_ERROR, "IndexSql module is NOT loaded.")
        end

        local sql = indexSql.FindIndex{[property]=value}
        res, err = mySql:query(sql)
        if not res then 
            self.reply = Err(ERR_STORE_OPERATION_FAILED, "operation Store.FindObj failed: %s", err)
            return self.reply
        end 
        if next(res) == nil then 
            return self.reply 
        end

        local id = res[1].entity_id
        res, err = mySql:query("select * from entity where id='"..id.."';")
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
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(prorperty) is missed")
    end 

    local createIndexSql = indexSql.CreateIndex(property)
    local ok, err = mySql:query(createIndexSql)
    if not ok then
        throw(ERR_SERVER_MYSQL_ERROR, "create %s_index table failed: %s", property, err)
    end

    return self.reply
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
        throw(ERR_SERVER_INVALID_PARAMETERS, "param(property) is missed")
    end

    local deleteIndexSql = indexSql.DeleteIndex(property)
    local ok, err = mySql:query(deleteIndexSql)
    if not ok then
        throw(ERR_SERVER_MYSQL_ERROR, "delete %s_index table failed: %s", property, err)
    end

    return self.reply
end

return StoreAction

