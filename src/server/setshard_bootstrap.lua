local dogs = ngx.shared.INDEXES
local v = "hello world" 
dogs:set("Jim", v)
ngx.say("STORED")
