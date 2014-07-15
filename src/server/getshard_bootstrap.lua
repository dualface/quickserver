local dogs = ngx.shared.INDEXES
local value = dogs:get("Jim")
ngx.say(value)
