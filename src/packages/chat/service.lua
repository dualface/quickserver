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
local type = type
local table_nums = table.nums
local json_encode = json.encode
local os_date = os.date

local ChatService = class("ChatService")

function ChatService:ctor(app)
    local config = nil
    if app then
        config = app.config.redis
        self.app = app
    end
    self.redis = cc.load("redis").service.new(config)
end

local function checkParams_(data, ...)
    local arg = {...}

    if table_nums(arg) == 0 then
        return true
    end

    for _, name in pairs(arg) do
        if data[name] == nil or data[name] == "" then
           return false
        end
    end

    return true
end

function ChatService:broadcast(data)
    if type(data) ~= "table" then
        return nil, "Parameter is not a table."
    end

    local rds = self.redis
    if rds == nil then
        return nil, "Service redis is not initialized."
    end

    if not checkParams_(data, "payload", "nickname", "to") then
        return nil, "'payload', 'nickname' or 'to' is missed in param table."
    end

    rds:connect()
    data.time = os_date("%Y-%m-%d %H:%M:%S")

    local to = data.to
    data.to = nil
    data.msg_id = nil

    for _, v in ipairs(to) do
        local sid = self.app:getSidByTag(v)
        if sid then
            self.app:sendMessage(sid, json_encode(data))
        end
    end

    rds:close()
    return true, nil
end

return ChatService
