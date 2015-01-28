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

local _DBG_ERROR = 0
local _DBG_WARN  = 1
local _DBG_INFO  = 2
local _DBG_DEBUG = 3

DEBUG = _DBG_DEBUG

local config = {
    appName                   = "myapp",

    appModuleName             = "sample",

    sessionExpiredTime        = 60*10,

    websocketsTimeout         = 60 * 1000, -- 60s
    websocketsMaxPayloadLen   = 16 * 1024, -- 16KB
    websocketsMessageFormat   = "json",
    maxWebsocketRetryCount    = 10,

    maxSubscribeRetryCount = 10,

    jobMessageFormat = "json",
    broadcastJobTube = "jobTube",

    redis = {
        host       = "127.0.0.1",
        port       = 6379,
        timeout    = 10 * 1000, -- 10 seconds
    },

    beanstalkd = {
        host       = "127.0.0.1",
        port       = 11300,
    },

    -- external servers used by user
    --[[
    externalServers = {
        mysql = {
            host       = "127.0.0.1",
            port       = 3306,
            database   = "testdb",
            user       = "test",
            password   = "123456",
            timeout    = 10 * 1000,
        },
    },
    --]]
}

return config
