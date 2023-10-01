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

-- "<variable>(, <variable>)* (= <expression>(, <expression>)*)?" 
function Statements:__VariableAssignment()
  local variables = {self:__Field()}
  while self:compareTokenValueAndType(self.currentToken, "Character", ",") do
    self:consume()
    insert(variables, self:__Field())
  end

  self:expectCurrentTokenAndConsume("Character", "=")
  
  return {
    Expressions = self:consumeMultipleExpressions(),
    Variables = variables,
    TYPE = "VariableAssignment"
  }
end
-- "[<identifier>, <vararg>]? [, <identifier>, <vararg>]*" 
function Statements:__FunctionParameters()
  local parameters = {}
  while true do
    local currentToken = self.currentToken
    local tokenType = currentToken.TYPE
    if tokenType == "Identifier" then
      insert(parameters, currentToken.Value)
    elseif tokenType == "Constant" and currentToken.Value == "..." then
      insert(parameters, "...")      
      -- There's no params after vararg.
      self:expectNextToken("Character", ")")
      break
    elseif tokenType == "Character" and currentToken.Value == ")" then
      break
    else
      -- An unknown token, ok
      -- Let parent functions deal with that crap
      break
    end
    if not self:compareTokenValueAndType(self:consume(), "Character", ",") then
      break
    end
    self:consume()
  end 

  return parameters
end
-- function(<args>) <code_block> end
function Statements:consumeFunction()
  self:consume() -- Consume the "function" keyword
  self:expectCurrentToken("Character", "(")
  self:consume() -- Consume "("
  local parameters = self:__FunctionParameters()
  self:expectCurrentToken("Character", ")")
  self:consume() -- Consume ")"
  local codeBlock = self:consumeCodeBlock({ "end" })
  self:expectCurrentToken("Keyword", "end")
  -- self:consume()
  return self:createFunctionNode(parameters, codeBlock)
end
-- <table>.<index>
function Statements:consumeTableIndex(currentExpression)
  self:consume() -- Consume the "." symbol
  local indexToken = self.currentToken

  if indexToken.TYPE == "Identifier" then
    indexToken.TYPE = "String"
  end

  return self:createIndexNode(indexToken, currentExpression)
end
-- <table>[<expression>]
function Statements:consumeBracketTableIndex(currentExpression)
  self:consume() -- Consume the "[" symbol
  local expression = self:consumeExpression()
  self:expectNextToken("Character", "]")
  return self:createIndexNode(expression, currentExpression)
end
-- <function_name>(<args>*)
function Statements:consumeFunctionCall(currentExpression)
  self:consume() -- Consume the "(" symbol
  
  -- Get parameters for the function
  local parameters = {};
  if not self:isClosingParenthesis(self.currentToken) then
    parameters = self:consumeMultipleExpressions()
    self:consume()
  end

  
  return self:createFunctionCallNode(currentExpression, parameters)
end
-- <table>:<method_name>(<args>*)
function Statements:consumeMethodCall(currentExpression)
  self:consume() -- Consume the ":" symbol
  local functionName = self.currentToken
  if functionName.TYPE ~= "Identifier" then
    return error("Incorrect function name")
  end
  self:consume() -- Consume the name of the method

  local functionCall = self:consumeFunctionCall(self:createIndexNode(functionName.Value, currentExpression))
  return self:createFunctionCallNode(functionCall.Expression, self:addSelfToArguments(functionCall.Parameters))
end
-- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , )? }*
function Statements:consumeTable()
  self:consume() -- Consume "{"
  
  local elements = {}
  local index = 1
  while not self:compareTokenValueAndType(self.currentToken, "Character", "}") do
    local curToken = self.currentToken
    if self:compareTokenValueAndType(curToken, "Character", "[") then
      self:consume() -- Consume "["
      local key = self:consumeExpression()
      self:expectNextToken("Character", "]")
      self:expectNextToken("Character", "=")
      self:consume() -- Consume "="
      local value = self:consumeExpression()
      insert(elements, self:createTableElementNode(key, value))
    elseif curToken.TYPE == "Identifier" and self:compareTokenValueAndType(self:peek(), "Character", "=") then
      local key =  curToken.Value
      self:consume() -- Consume key
      self:consume() -- Consume "="
      local value = self:consumeExpression()
      insert(elements, self:createTableElementNode(key, value))
    else
      local value = self:consumeExpression()
      insert(elements, self:createTableElementNode(self:createNumberNode(index), value))
      index = index + 1
    end

    self:consume() -- Consume the last token of the expression
    if self:compareTokenValueAndType(self.currentToken, "Character", ",") then
      self:consume()
    else
      -- Break the loop, it will error if this is not the true end anyway.
      break
    end
  end

  -- self:consume() -- Consume "}"
  return self:createTableNode(elements) 
end
function Statements:handleSpecialOperators(token, leftExpr)
  if token.TYPE == "Character" then
    -- <table>.<index>
    if token.Value == "." then return self:consumeTableIndex(leftExpr)
    -- <table>[<expression>]
    elseif token.Value == "[" then return self:consumeBracketTableIndex(leftExpr) 
    -- <table>:<method_name>(<args>*)
    elseif token.Value == ":" then return self:consumeMethodCall(leftExpr)
    -- <function_name>(<args>*)
    elseif token.Value == "(" then return self:consumeFunctionCall(leftExpr)
    end
  end
end
function Statements:handleSpecialOperands(token)
  if token.TYPE == "Character" then
     -- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , )? }*
    if token.Value == "{" then return self:consumeTable() end
  elseif token.TYPE == "Keyword" then
    -- function(<args>) <code_block> end
    if token.Value == "function" then return self:consumeFunction() end
  end
end
-- <table>.<index> | <table>[<expression>]
function Statements:_TableIndex(tableNode)
  local curToken = self:expectCurrentToken("Character")

  if curToken.Value == "." then return self:consumeTableIndex(tableNode)
  elseif curToken.Value == "[" then return self:consumeBracketTableIndex(tableNode)
  end
end
-- "<identifier> | (<identifier>(. <identifier>)*) | (<identifier>[<expression>])"
function Statements:__Field()
  local identifier = self:expectCurrentToken("Identifier")
  
  self:consume()
  if self:tokenIsOneOf(self.currentToken, {{"Character", "."}, {"Character", "["}}) then
    local tableElement = identifier
    repeat
      tableElement = self:_TableIndex(tableElement)
      self:consume()
    until not (self:tokenIsOneOf(self.currentToken, {{"Character", "."}, {"Character", "["}}))
    
    return tableElement
  end
  
  return identifier
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
    local parameters = self:__FunctionParameters()
    self:expectCurrentTokenAndConsume("Character", ")")
    local codeBlock = self:consumeCodeBlock({"end"})
    return {
      TYPE = "LocalFunction",
      Name = functionName,
      Parameters = parameters,
      CodeBlock = codeBlock
    }
  end

  local variables = self:consumeMultipleIdentifiers(true)
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
      Condition = self:consumeExpression(),
      TYPE = "ElseIfStatement",
    }
    self:expectNextTokenAndConsume("Keyword", "then")
    newElseIf.CodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
    insert(newIfStatement.ElseIfs, newElseIf)
  end
  -- Consume an optional "else" statement
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
    self:consume() -- Consume "else"
    newIfStatement.Else.CodeBlock = self:consumeCodeBlock({"end"})
    newIfStatement.Else.TYPE = "elseStatement"
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
  local parameters = {};

  local currentToken = self.currentToken
  while self:compareTokenValueAndType(currentToken, "Character", ".") or (not isLocal and self:compareTokenValueAndType(currentToken, "Character", ":")) do
    local previousToken = currentToken
    self:consume() -- Consume ":" or "."
    local identifier = self:expectCurrentToken("Identifier")
    insert(fields, identifier.Value)
    currentToken = self:consume()
    if self:compareTokenValueAndType(previousToken, "Character", ":") then
      insert(parameters, "self")
      break
    end
  end

  self:expectCurrentTokenAndConsume("Character", "(")
  parameters = self:__FunctionParameters() 
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return {
    TYPE = "Function",
    Fields = fields,
    Parameters = parameters,
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