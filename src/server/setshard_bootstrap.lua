local dogs = ngx.shared.dogs
local tbl = {x=1} 
dogs:set("Jim", tbl)
ngx.say("STORED")
