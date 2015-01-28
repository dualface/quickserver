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

local string_format = string.format

local ObjectstorageAction = class("ObjectstorageAction")

local function err_(...)
   return {err_msg = string_format(...)}
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

    return {keys = ok}
end

return ObjectstorageAction
