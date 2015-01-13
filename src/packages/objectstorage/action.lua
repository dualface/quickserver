local strFormat = string.format

local ObjectstorageAction = class("ObjectstorageAction")

local function err_(...) 
   return {err_msg = strFormat(...)} 
end

local service = import(".service")

function ObjectstorageAction:ctor(app)
    self.objStorageService = service.new(app)
end

function ObjectstorageAction:saveobjAction(data) 
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:saveObj(data)
    if not ok then
        return err_(err)
    end

    return {id = ok} 
end 

function ObjectstorageAction:updateobjAction(data)
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:updateObj(data)
    if not ok then
        return err_(err)
    end

    return {id = ok}
end

function ObjectstorageAction:deleteobjAction(data)
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:deleteObj(data)
    if not ok then
        return err_(err)
    end

    return {id = ok}
end

function ObjectstorageAction:findobjAction(data) 
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local res, err = s:findObj(data)
    if not res then
        return err_(err)
    end

    return {objs=res}
end

function ObjectstorageAction:createindexAction(data)
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:createIndex(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1} 
end

function ObjectstorageAction:deleteindexAction(data) 
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:deleteIndex(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1}
end

function ObjectstorageAction:showindexAction(data)
    local s = self.objStorageService
    if not s then
        return err_("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:showIndex(data)
    if not ok then
        return err_(err)
    end

    return {ok = 1}
end

return ObjectstorageAction
