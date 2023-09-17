--[[
  Name: KeywordsParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/Parser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local byte = string.byte
local concat = table.concat
local char = string.char
local rep = string.rep
local find = table.find or Helpers.TableFind

local keywords = {
  -- "local <identifier>[, <identifier>]* = <expression>[, <expression>]*" OR
  -- "local <identifier>[, <identifier>]*"
  ["_local"] = function(self)
    local variables = {}
    repeat
      insert(variables, self:expectNextToken("Identifier").Value)
      self:consume()
    until not (self:compareTokenValueAndType(self.currentToken, "Character", ","))
    if not self:compareTokenValueAndType(self.currentToken, "Character", "=") then
      return {
        TYPE = "LocalVariable",
        Variables = variables
      }
    end
    
    self:expectCurrentToken("Character", "=")
    self:consume()
    return {
      Expressions = self:consumeMultipleExpressions(),
      Variables = variables,
      TYPE = "LocalVariable"
    }
  end,

  -- "if <expression> then <codeblock> [elseif <expression> then <codeblock>]* [else <codeblock>]? end"
  ["_if"] = function(self)
    self:consume()
    local statement = self:consumeExpression()
    self:expectNextToken("Keyword", "then")
    self:consume()
    local codeBlock = self:consumeCodeBlock({"end"})
    self:expectCurrentToken("Keyword", "end")
    return {
      TYPE = "IfStatement",
      Statement = statement,
      CodeBlock = codeBlock
    }
  end;

  -- "for <identifier>, [<identifier>, ]"
}

return keywords