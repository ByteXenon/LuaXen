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
  -- "return [<expression>?[, <expression>]*]?"
  _return = function(self)
    self:consume() -- Consume "return"
    return {
      TYPE = "Return",
      Values = self:consumeMultipleExpressions()
    }
  end,

  -- "local <identifier>[, <identifier>]* = <expression>[, <expression>]*" |
  -- "local <identifier>[, <identifier>]*"
  _local = function(self)
    self:consume() -- Consume "local"
    local variables = self:consumeMultipleIdentifiers(true)
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
  _if = function(self)
    self:consume() -- Consume "if"
    
    local newIfStatement = {
      Statement = self:consumeExpression(),
      CodeBlock = {},
      ElseIfs = {},
      Else = {}
    }

    self:expectNextToken("Keyword", "then")
    self:consume() -- Consume "then"
    newIfStatement.CodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})

    -- Consume multiple "elseif" statements if there's any
    while self:compareTokenValueAndType(self.currentToken, "Keyword", "elseif") do
      self:consume() -- Consume "elseif"
      local newElseIf = {
        Statement = self:consumeExpression()
      }
      self:expectNextToken("Keyword", "then")
      self:consume() -- Consume "then"
      newElseIf.CodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
      insert(newIfStatement.ElseIfs, newElseIf)
    end
    -- Consume an optional "else" statement
    if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
      self:consume() -- Consume "else"
      newIfStatement.Else = {
        CodeBlock = self:consumeCodeBlock({"end"})
      }
    end

    return newIfStatement
  end;

  -- "for <identifier>, [<identifier>, ]"
}

return keywords