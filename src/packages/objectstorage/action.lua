local ObjectstorageAction = class("ObjectstorageAction")

local function _err(...) 
   return {err_msg = string.format(...)} 
end

local service = import(".service")

function ObjectstorageAction:ctor(app, cls)
    if cls == nil then 
       echoError("Please specify a class to carry pakcage actions,  or you can import pakcage service only.") 
       return 
    end

    -- export action method
    local find = string.find
    for k, v in pairs(self.class) do
        if type(v) == "function" and find(k, "Action$") then
            cls[k] = v 
        end
    end
    cls.service = service.new(app)
end

function ObjectstorageAction:SaveobjAction(data) 
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:SaveObj(data)
    if not ok then
        return _err(err)
    end

    return {id = ok} 
end 

function ObjectstorageAction:UpdateobjAction(data)
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:Updateobj(data)
    if not ok then
        return _err(err)
    end

    return {id = ok}
end

function ObjectstorageAction:DeleteobjAction(data)
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:Deleteobj(data)
    if not ok then
        return _err(err)
    end

    return {id = ok}
end

function ObjectstorageAction:FindobjAction(data) 
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local res, err = s:Findobj(data)
    if not res then
        return _err(err)
    end

    return {objs=res}
end

function ObjectstorageAction:CreateindexAction(data)
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:Createindex(data)
    if not ok then
        return _err(err)
    end

    return {ok = 1} 
end

function ObjectstorageAction:DeleteindexAction(data) 
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:Deleteindex(data)
    if not ok then
        return _err(err)
    end

    return {ok = 1}
end

function ObjectstorageAction:ShowindexAction(data)
    local s = self.service
    if not s then
        return _err("ObjectstorageAction is not initialized.")
    end

    local ok, err = s:Showindex(data)
    if not ok then
        return _err(err)
    end

    return {ok = 1}
end

return ObjectstorageAction
