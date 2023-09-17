--[[
  Name: SyntaxStatementParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/SyntaxStatementParser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local insert = table.insert
local byte = string.byte
local concat = table.concat
local char = string.char
local find = table.find or Helpers.TableFind
local rep = string.rep

local SyntaxStatementParser = {}
function SyntaxStatementParser:new(interpreter)
  local SyntaxStatementParserInstance = {}

  local interpreter = interpreter
  
  function SyntaxStatementParserInstance:consume(keyword)
    return self["consume" .. keyword](self)
  end;

  function SyntaxStatementParserInstance:consumeif()
    local expression = interpreter:consumeExpression()
    return {
      TYPE = "IfStatement",
      Expression = expression
    }
  end;

  return SyntaxStatementParserInstance
end;

return SyntaxStatementParser