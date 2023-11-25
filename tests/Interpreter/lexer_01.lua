local TestsLibrary = require("../tests/TestsLibrary")
local LuaLexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")


local tablesEqual = TestsLibrary.tablesEqual

do -- Simple 01
  local expectedReturn = {
    { Value = "do",  Type = "Keyword" },
    { Value = "end", Type = "Keyword" }
  }

  local instance = LuaLexer:new("do end")
  local tokens = instance:tokenize()
  if not tablesEqual(expectedReturn, tokens) then
    error("Simple_01: unexpected result")
  else
    print("Simple_01: pass")
  end
end