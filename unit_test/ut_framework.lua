package.path = package.path .. ";/opt/qs/src/?.lua;/opt/qs/bin/openresty/lualib/?.lua;;"

local assert = assert 
local type = type
local print = print
local pairs = pairs
local string_format = string.format
local table_cocat = table.concat
local table_insert = table.insert
local string_find = string.find

local printf = function(fmt, ...)
    local msg = string_format(fmt, ...)    
    print(msg.."\n")
end

local println = function()
    printf("")
end

local _tests = {}

local function _runAllCase()
    local allTestResut = 1
    local suitNum = 0
    local passed = 0
    local failed = 0

    for suitName, _cases in pairs(_tests) do 
        printf("Test %s", suitName)
        printf("======================================")

        local testSuitPassed = 0
        local testSuitFailed = 0
        for caseName, steps in pairs(_cases) do 
            assert(type(steps) == "table")

            printf("Run TestCase: %s", caseName)
            local run = loadstring(table_cocat(steps, "\n"))
            local r = run() 
            printf("End TestCase: %s", caseName) 
            printf("---")
            if r then
                testSuitPassed = testSuitPassed + 1
            else
                testSuitFailed = testSuitFailed + 1
                allTestResut = 0
            end
        end

        printf("======================================")
        printf("Total TestCase in %s: %d",  suitName, testSuitPassed + testSuitFailed)
        printf("Passed: %d", testSuitPassed)
        printf("Failed: %d", testSuitFailed)
        println()

        suitNum = suitNum + 1
        passed = passed + testSuitPassed 
        failed = failed + testSuitFailed
    end 
    
    printf("Summarize %d TestSuits", suitNum)
    printf("======================================")
    printf("Total TestCase: %d", passed + failed)
    printf("Passed: %d", passed)
    printf("Failed: %d", failed)
    printf("======================================")

    return allTestResut 
end

local function _runCase(testSuitName, testCaseName)
end

local function _register(testSuitName, testCaseName)
    assert(type(testSuitName) == "string")
    assert(type(testCaseName) == "string")

    _tests[testSuitName] = _tests[testSuitName] or {}
    _tests[testSuitName][testCaseName] = _tests[testSuitName][testCaseName] or {}

    return _tests[testSuitName][testCaseName]
end

function BEGIN_CASE(testSuitName, testCaseName)
    return _register(testSuitName, testCaseName) 
end

function END_CASE(steps)
    assert(type(steps) == "table")

    local codes = [[do
        return true
    end]]
    table_insert(steps, codes)
end

function RUN_ALL_CASES() 
    _runAllCase()
end

-- expections

-- boolean
function EXPECT_TRUE(steps, condition)
    assert(type(steps) == "table")  

    if condition == false then
        local codes = [[do 
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

function EXPECT_FALSE(steps, condition)
    assert(type(steps) == "table")
    
    if condition == true then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

-- numeric
function EXPECT_EQ(steps, expected, actual)
    assert(type(steps) == "table") 

    if expected ~= actual then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

function EXPECT_NE(steps, val1, val2)
    assert(type(steps) == "table")

    if val1 == val2 then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

-- string
function EXPECT_STREQ(steps, expectedStr, actualStr)
    assert(type(steps) == "table")

    if expectedStr ~= actualStr then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

function EXPECT_STRNE(steps, str1, str2)
    assert(type(steps) == "table")

    if str1 == str2 then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

function EXPECT_NOCASE_STREQ(steps, expectedStr, actualStr)
    assert(type(steps) == "table")

    if string_lower(expectedStr) ~= string_lower(actualStr) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

function EXPECT_NOCASE_STRNE(steps, str1, str2)
    assert(type(steps) == "table")

    if string_lower(str1) == string_lower(str2) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(steps, codes)
    end
end

-- error
function EXPECT_ERROR(steps, errMsg, func, arg1, ...)
    assert(type(steps) == "table")

    local ok, res = pcall(func, arg1, ...)
    if ok or not string_find(res, errMsg) then
        local codes = [[do
            return false
        end
        ]]
    end
end
