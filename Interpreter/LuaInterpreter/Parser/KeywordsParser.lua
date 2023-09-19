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

local keywords = {}

-- "return( <expression>(, <expression>)*)?"
function keywords._return(self)
  self:consume() -- Consume "return"
  
  return {
    TYPE = "Return",
    Values = self:consumeMultipleExpressions()
  }
end
-- "local <identifier>(, <identifier>)* (= <expression>(, <expression>)*)?"
function keywords._local(self)
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
end
-- "if <expression> then <codeblock>( elseif <expression> then <codeblock>)*( else <codeblock>)? end"
function keywords._if(self)
  self:consume() -- Consume "if"
  
  local newIfStatement = {
    Statement = self:consumeExpression(),
    CodeBlock = {},
    ElseIfs = {},
    Else = {},
    TYPE = "IfStatement"
  }

  self:expectNextTokenAndConsume("Keyword", "then")
  newIfStatement.CodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})

  -- Consume multiple "elseif" statements if there's any
  while self:compareTokenValueAndType(self.currentToken, "Keyword", "elseif") do
    self:consume() -- Consume "elseif"
    local newElseIf = {
      Statement = self:consumeExpression()
    }
    self:expectNextTokenAndConsume("Keyword", "then")
    newElseIf.CodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
    insert(newIfStatement.ElseIfs, newElseIf)
  end
  -- Consume an optional "else" statement
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
    self:consume() -- Consume "else"
    newIfStatement.Else = self:consumeCodeBlock({"end"})
  end

  return newIfStatement
end
-- "repeat <codeblock> until <expression>"
function keywords._repeat(self)
  self:consume() -- Consume "repeat"
  local codeBlock = self:consumeCodeBlock({"until"})
  self:expectCurrentTokenAndConsume("Keyword", "until")
  local statement = self:consumeExpression()
  
  return {
    TYPE = "Until",
    CodeBlock = codeBlock,
    Statement = statement
  }
end
-- "do <code_block> end"
function keywords._do(self)
  self:consume() -- Consume "do"
  local codeBlock = self:consumeCodeBlock({"end"})

  return {
    TYPE = "Do",
    CodeBlock = codeBlock
  }
end
-- "while <expression> do <code_block> end"
function keywords._while(self)
  self:consume() -- Consume "while"
  local expression = self:consumeExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return {
    TYPE = "WhileLoop",
    Expression = expression,
    CodeBlock = codeBlock
  }
end
-- "break"
function keywords._break(self)
  return {
    TYPE = "Break"
  }
end
-- "continue"
function keywords._continue(self)
  return {
    TYPE = "Continue"
  }
end

-- "for <identifier>(, <identifier>)* in <expression> do <codeblock> end"
local function consumeGenericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Keyword", "in")
  local expression = self:consumeExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return {
    TYPE = "GenericFor",
    IteratorVariables = iteratorVariables,
    Expression = expression,
    CodeBlock = codeBlock
  }
end
-- "for <identifier> = <expression>, <expression>(, <expression>)? do <codeblock> end"
local function consumeNumericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:consumeMultipleExpressions(3)
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})

  return {
    TYPE = "NumericFor",
    IteratorVariables = iteratorVariables,
    Expressions = expressions,
    CodeBlock = codeBlock
  }
end
-- "for <identifier>(, <identifier>)* in <expression> do <codeblock> end" |
-- "for <identifier> = <expression>, <expression>(, <expression>)? do <codeblock> end"
function keywords._for(self)
  self:consume() -- Consume "for"
  local iteratorVariables = {
    self:expectCurrentToken("Identifier")
  }
  while self:compareTokenValueAndType(self:consume(), "Character", ",")  do
    insert(iteratorVariables, self:expectNextToken("Identifier"))
  end
  if #iteratorVariables > 1 or self:compareTokenValueAndType(self.currentToken, "Keyword", "in") then
    return consumeGenericLoop(self, iteratorVariables)
  end
  return consumeNumericLoop(self, iteratorVariables)
end

return keywords