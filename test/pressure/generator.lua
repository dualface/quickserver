local luaPath = package.path
local jsonPath = [[;/home/cheeray/work/quick-x-server/src/?.lua]]
package.path = luaPath .. jsonPath
-- print(package.path)

local json = require("framework.json")

local function generator(index) 
    local tbl = {}
    tbl._msgid = index
    tbl.action = "store.saveObj"

    local rawdata = {} 
    local key1 = {key1 = "pressure_key" .. index}
    local property = {property = "pressure_property"..index}
    local i_name = {i_name = "pressure_i_name"..index}
    
    table.insert(rawdata, key1)
    table.insert(rawdata, property)
    table.insert(rawdata, i_name)

    local indexes = {} 
    table.insert(indexes, "i_name")
    table.insert(indexes, "property")

    tbl.rawdata = rawdata
    tbl.indexes = indexes

    local jsonStr = json.encode(tbl)

    return jsonStr
end

local jsonStr = generator(1) 

print(jsonStr)

