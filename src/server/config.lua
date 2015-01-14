local config = {
    appModuleName             = "server",
    debug                     = true,

    websocketsTimeout         = 60 * 1000, -- 60s
    websocketsMaxPayloadLen   = 16 * 1024, -- 16KB
    websocketsMessageFormat   = "json",
    maxWebsocketRetryCount    = 60, 

    chatChannelPattern = "channel.chat.%s",
    jobChannelPattern = "channel.job.%s",
    chatChannelCapacity = 1000,
    jobChannelCapacity = 100, 
    maxSubscribeRetryCount = 60,

    sharedMemoryDictName      = "TestApp",

    sessionExpired = 1200,

    workQueue = "BackgroundWork",
    workerMessageFormat = "json",

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
    
    chat = {
        recordNum = 100,
        channelNum = 100,
        peoplePerCh = 200,
    },
}

return config
