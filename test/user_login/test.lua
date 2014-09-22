--local COCOSCHINA = [[http://open.cocoachina.com/api/user_login]]
--local COCOSCHINA = [[http://localhost:8088/_server/user/login]]

url = require("resty.url")

local str = [[password=9bb4aa9034e9b399b5a77a3a49e376bd&sign=61694F908853A4F40757182BB451A1DA&username=hqycxy&from=quickcocos2dx&timestamp=1411117923]]

print(url.escape(str))

