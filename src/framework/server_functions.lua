--[[

Copyright (c) 2011-2015 dualface#github

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

local string_split = string.split
local string_len = string.len
local string_find = string.find
local string_sub = string.sub
local string_byte = string.byte
local string_gsub = string.gsub

function strip_paths(str, paths)
    paths = paths or string_split(package.path, ";")
    paths = checktable(paths)

    table.sort(paths, function(a, b)
        return string_len(a) >= string_len(b)
    end)

    for _, path in ipairs(paths) do
        local pos = string_find(path, "?", 0, true)
        if pos then
            path = string_sub(path, 1, pos - 1)
        end
        if string_byte(path) == 47 then
            str = string_gsub(str, path, "")
        end
    end

    return str
end
