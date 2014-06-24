
local config = {
    appModuleName             = "server",
    debug                     = true,

    websocketsTimeout         = 60 * 1000, -- 60s
    websocketsMaxPayloadLen   = 16 * 1024, -- 16KB
    websocketsMessageFormat   = "json",

    pushMessageChannelPattern = "channel.%s",
    sharedMemoryDictName      = "TestApp",

    redis = {
        host       = "127.0.0.1",
        port       = 6379,
        timeout    = 10 * 1000, -- 10 seconds
    },

    beanstalkd = {
        host       = "127.0.0.1",
        port       = 11300,
        timeout    = 10 * 1000, -- 10 seconds
    },

    mysql = {
        host       = "127.0.0.1",
        port       = 3306,
        database   = "testdb",
        user       = "test",
        password   = "123456",
        timeout    = 10 * 1000,
    },
}

return config
