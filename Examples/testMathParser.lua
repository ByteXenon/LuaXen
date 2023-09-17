--[[
  Name: testMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Examples/testMathParser")

-- Define expressions to test (valid and invalid)
local expressions = {
  -- Valid expressions
  "-(1)",
  "(((1 + 2) * 3 - 4) / 5) % 6",
  "-(-(-10^- - -3) * -2) + -(8 / -2)",
  "5 ^ 2 + 4 * 3",
  "1 + 2 * 3 / 4 - 5 ^ 6",
  "(2 + 3) * (4 - 1)",
  "((8 / 2) + 3) * (7 - 4)",
  "3 + -2",
  "-(-3)",
  
  -- Invalid expressions
  "1 + 2 )",
  "(1 + 2",
  "5 + * 2",
  "1 ++ 2",
  "+ 3",
}

-- Load the MathParser module
local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/MathParser")
local myMathParser = MathParser:new()

-- Test each expression
for _, expression in ipairs(expressions) do
  local success, errorMessage = pcall(function()
    local result = myMathParser:solve(expression)
    local expected = loadstring("return " .. expression)()

    -- Print results
    print("Expression:", expression)
    print("Parsed Result:", result)
    print("Expected Result:", expected)
    print("Result Match:", result == expected)
    print("-----------------------------")
  end)

  -- Print error message if failed
  if not success then
    print("Expression:", expression)
    print("Error:", errorMessage)
    print("-----------------------------")
  end
end