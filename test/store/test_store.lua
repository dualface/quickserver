LUA_PATH = "/opt/quick_server/openresty/lualib/?.lua;;"

local server = require("resty.websocket.server")

print(server)
