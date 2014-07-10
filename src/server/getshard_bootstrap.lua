local dogs = ngx.shared.dogs
local tbl = dogs:get("Jim")
ngx.say(tbl.x)
i--ngx.say(dogs:get("Jim"))
