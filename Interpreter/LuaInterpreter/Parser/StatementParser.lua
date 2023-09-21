--[[
  Name: StatementParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/StatementParser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local find = table.find or Helpers.TableFind

--* Statements *--
local Statements = {}

-- "<identifier>(, <identifier>)* (= <expression>(, <expression>)*)?" 
function Statements:__VariableAssignment()
  local variables = self:identifiersToValues(self:consumeMultipleIdentifiers(true))
  self:expectCurrentTokenAndConsume("Character", "=")
  return {
    Expressions = self:consumeMultipleExpressions(),
    Variables = variables,
    TYPE = "VariableAssignment"
  }
end
-- "local <identifier>(, <identifier>)* (= <expression>(, <expression>)*)?" |
-- "local function <identifier>(<args>) <code_block> end"
function Statements:_local()
  self:consume() -- Consume "local"
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "function") then
    self:consume() -- Consume "function"
    local functionName = self:expectCurrentToken("Identifier").Value
    self:consume()
    self:expectCurrentTokenAndConsume("Character", "(")
    local arguments = self:identifiersToValues(self:consumeMultipleIdentifiers())
    self:expectCurrentTokenAndConsume("Character", ")")
    local codeBlock = self:consumeCodeBlock({"end"})
    return {
      TYPE = "LocalFunction",
      Name = functionName,
      Arguments = arguments,
      CodeBlock = codeBlock
    }
  end

  local variables = self:identifiersToValues(self:consumeMultipleIdentifiers(true))
  if not self:compareTokenValueAndType(self.currentToken, "Character", "=") then
    return {
      TYPE = "LocalVariable",
      Variables = variables
    }
  end

  self:expectCurrentTokenAndConsume("Character", "=")
  
  return {
    Expressions = self:consumeMultipleExpressions(),
    Variables = variables,
    TYPE = "LocalVariable"
  }
end
-- "if <expression> then <codeblock>( elseif <expression> then <codeblock>)*( else <codeblock>)? end"
function Statements:_if()
  self:consume() -- Consume "if"
  
  local newIfStatement = {
    Condition = self:consumeExpression(),
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
      Condition = self:consumeExpression()
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
function Statements:_repeat()
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
function Statements:_do()
  self:consume() -- Consume "do"
  local codeBlock = self:consumeCodeBlock({"end"})

  return {
    TYPE = "Do",
    CodeBlock = codeBlock
  }
end
-- "while <expression> do <code_block> end"
function Statements:_while()
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
-- "return( <expression>(, <expression>)*)?"
function Statements:_return()
  self:consume() -- Consume "return"
  
  return {
    TYPE = "Return",
    Expressions = self:consumeMultipleExpressions()
  }
end
-- "break"
function Statements:_break()
  return {
    TYPE = "Break"
  }
end
-- "continue"
function Statements:_continue()
  return {
    TYPE = "Continue"
  }
end
-- "function <identifier>[. <identifier>]*[: <identifier>]?(<args>) <code_block> end"
function Statements:_function(isLocal)
  self:consume() -- Consume "function"
  local fields = {
    self:expectCurrentToken("Identifier").Value
  }
  self:consume() -- Consume the first required field
  local arguments = {};

  local currentToken = self.currentToken
  while self:compareTokenValueAndType(currentToken, "Character", ".") or (not isLocal and self:compareTokenValueAndType(currentToken, "Character", ":")) do
    local previousToken = currentToken
    self:consume() -- Consume ":" or "."
    local identifier = self:expectCurrentToken("Identifier")
    insert(fields, identifier.Value)
    currentToken = self:consume()
    if self:compareTokenValueAndType(previousToken, "Character", ":") then
      insert(arguments, "self")
      break
    end
  end

  self:expectCurrentTokenAndConsume("Character", "(")
  for _, identifier in pairs(self:consumeMultipleIdentifiers()) do
    insert(arguments, identifier.Value)
  end
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return {
    TYPE = "Function",
    Fields = fields,
    Arguments = arguments,
    CodeBlock = codeBlock
  }
end
-- "in <expression> do <codeblock> end"
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
-- "= <expression>, <expression>(, <expression>)? do <codeblock> end"
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
function Statements:_for()
  self:consume() -- Consume "for"
  local iteratorVariables = {
    self:expectCurrentToken("Identifier").Value
  }
  while self:compareTokenValueAndType(self:consume(), "Character", ",")  do
    insert(iteratorVariables, self:expectNextToken("Identifier").Value)
  end
  if #iteratorVariables > 1 or self:compareTokenValueAndType(self.currentToken, "Keyword", "in") then
    return consumeGenericLoop(self, iteratorVariables)
  end
  return consumeNumericLoop(self, iteratorVariables)
end

return Statements