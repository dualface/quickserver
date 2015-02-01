require("framework.functions")

local _TEST_SUIT_NAME = "framework_functions"

local _steps = BEGIN_CASE(_TEST_SUIT_NAME, "THROW_AN_ERROR")
    EXPECT_ERROR(_steps, "test error", throw, "test error")  
END_CASE(_steps)

local _steps = BEGIN_CASE(_TEST_SUIT_NAME, "CHECKNUMBER_OK")
    EXPECT_EQ(_steps, 5, checknumber(5))
END_CASE(_steps)

local _steps = BEGIN_CASE(_TEST_SUIT_NAME, "CHECKNUMBER_NOK")
    EXPECT_EQ(_steps, 0, checknumber("string"))
END_CASE(_steps)
