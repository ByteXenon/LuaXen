--[[
  Name: StatementParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
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
function Statements:__VariableAssignment(variables)
  local variables = variables or {self:__Field()}
  while self:compareTokenValueAndType(self.currentToken, "Character", ",") do
    self:consume()
    insert(variables, self:__Field())
  end

  self:expectCurrentTokenAndConsume("Character", "=")
  
  return self:createVariableAssignmentNode(self:consumeMultipleExpressions(), variables)
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
      -- Let parent functions deal with this crap
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
  
  -- Get arguments for the function
  local arguments = {};
  if not self:isClosingParenthesis(self.currentToken) then
    arguments = self:consumeMultipleExpressions()
    self:consume()
  end
  
  return self:createFunctionCallNode(currentExpression, arguments)
end
-- <table>:<method_name>(<args>*)
function Statements:consumeMethodCall(currentExpression)
  self:consume() -- Consume the ":" symbol
  local functionName = self.currentToken
  if functionName.TYPE ~= "Identifier" then
    return error("Incorrect function name")
  end
  self:consume() -- Consume the name of the method

  local functionCall = self:consumeFunctionCall(self:createMethodIndexNode(functionName, currentExpression))
  return self:createMethodCallNode(functionCall.Expression, functionCall.Arguments)
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
      local key =  curToken
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
-- "local function <identifier>(<args>) <code_block> end"
function Statements:_localFunction()
  self:consume() -- Consume "local"
  self:expectCurrentTokenAndConsume("Keyword", "function") -- Consume "function"
  local functionName = self:expectCurrentToken("Identifier").Value
  self:consume()
  self:expectCurrentTokenAndConsume("Character", "(")
  local parameters = self:__FunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"})
  return self:createLocalFunctionNode(functionName, parameters, codeBlock)
end
-- "local <identifier>(, <identifier>)* (= <expression>(, <expression>)*)?" |
-- "local function <identifier>(<args>) <code_block> end"
function Statements:_local()
  if self:compareTokenValueAndType(self:peek(), "Keyword", "function") then
    return self:_localFunction()
  end
  self:consume() -- Consume "local"
  local variables = self:consumeMultipleIdentifiers(true)
  if not self:compareTokenValueAndType(self.currentToken, "Character", "=") then
    return self:createLocalVariableNode(variables)
  end

  self:expectCurrentTokenAndConsume("Character", "=")
  
  local expressions = self:consumeMultipleExpressions()
  return self:createLocalVariableNode(variables, expressions)
end
-- "if <expression> then <codeblock>( elseif <expression> then <codeblock>)*( else <codeblock>)? end"
function Statements:_if()
  self:consume() -- Consume "if"

  local expression = self:consumeExpression()
  self:expectNextTokenAndConsume("Keyword", "then")
  local ifStatementCodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
  local newIfStatement = self:createIfStatementNode(expression, ifStatementCodeBlock, {})

  -- Consume multiple "elseif" statements if there's any
  while self:compareTokenValueAndType(self.currentToken, "Keyword", "elseif") do
    self:consume() -- Consume "elseif"
    local elseIfCondition = self:consumeExpression()
    self:expectNextTokenAndConsume("Keyword", "then")
    local elseIfCodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
    insert(newIfStatement.ElseIfs, self:createElseIfStatementNode(elseIfCondition, elseIfCodeBlock))
  end
  -- Consume an optional "else" statement
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
    self:consume() -- Consume "else"
    local elseCodeBlock = self:consumeCodeBlock({"end"})
    newIfStatement.Else = self:createElseStatementNode(elseCodeBlock)
  end

  return newIfStatement
end
-- "repeat <codeblock> until <expression>"
function Statements:_repeat()
  self:consume() -- Consume "repeat"
  local codeBlock = self:consumeCodeBlock({"until"})
  self:expectCurrentTokenAndConsume("Keyword", "until")
  local statement = self:consumeExpression()
  
  return self:createUntilLoopNode(codeBlock, statement)
end
-- "do <code_block> end"
function Statements:_do()
  self:consume() -- Consume "do"
  local codeBlock = self:consumeCodeBlock({"end"})

  return self:createDoBlockNode(codeBlock)
end
-- "while <expression> do <code_block> end"
function Statements:_while()
  self:consume() -- Consume "while"
  local expression = self:consumeExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return self:createWhileLoopNode(expression, codeBlock)
end
-- "return( <expression>(, <expression>)*)?"
function Statements:_return()
  self:consume() -- Consume "return"
  local expressions = self:consumeMultipleExpressions()

  return self:createReturnStatementNode(expressions)
end
-- "break"
function Statements:_break()
  return self:createBreakStatementNode()
end
-- "continue"
function Statements:_continue()
  return self:createContinueStatementNode()
end
-- ":<identifier>(<args>) <code_block> end"
function Statements:_method(fields)
  self:consume() -- Consume ":"
  local methodName = self:expectCurrentToken("Identifier")
  insert(fields, methodName.Value)
  self:consume() -- Consume method name
  
  self:expectCurrentTokenAndConsume("Character", "(")
  local parameters = self:__FunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"})

  return self:createMethodDeclarationNode(parameters, codeBlock, fields)
end
-- "function <identifier>[. <identifier>]*[: <identifier>]?(<args>) <code_block> end"
function Statements:_function(isLocal)
  self:consume() -- Consume "function"
  local fields = {self:expectCurrentToken("Identifier").Value}
  self:consume() -- Consume the first identifier field

  local currentToken = self.currentToken
  
  -- [. <identifier>]*
  while self:compareTokenValueAndType(currentToken, "Character", ".") do
    local previousToken = currentToken
    self:consume() -- Consume "."
    local identifier = self:expectCurrentToken("Identifier")
    insert(fields, identifier.Value)
    currentToken = self:consume() -- Consume field
  end
  -- [[: <identifier>](<args>) <code_block> end ]?
  if (not isLocal and self:compareTokenValueAndType(currentToken, "Character", ":")) then
    -- Consume it as a method declaration instead.
    return self:_method(fields)
  end

  self:expectCurrentTokenAndConsume("Character", "(")
  local parameters = self:__FunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return self:createFunctionDeclarationNode(parameters, codeBlock, fields)
end
-- "in <expression> do <codeblock> end"
local function consumeGenericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Keyword", "in")
  local expression = self:consumeExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})
  
  return self:createGenericForNode(iteratorVariables, expression, codeBlock)
end
-- "= <expression>, <expression>(, <expression>)? do <codeblock> end"
local function consumeNumericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:consumeMultipleExpressions(3)
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})

  return self:createNumericForNode(iteratorVariables, expressions, codeBlock)
end
-- "for <identifier>(, <identifier>)* in <expression> do <codeblock> end" |
-- "for <identifier> = <expression>, <expression>(, <expression>)? do <codeblock> end"
function Statements:_for()
  self:consume() -- Consume "for"
  local iteratorVariables = {self:expectCurrentToken("Identifier").Value}
  -- <identifier>(, <identifier>)*
  while self:compareTokenValueAndType(self:consume(), "Character", ",")  do
    insert(iteratorVariables, self:expectNextToken("Identifier").Value)
  end
  if #iteratorVariables > 1 or self:compareTokenValueAndType(self.currentToken, "Keyword", "in") then
    return consumeGenericLoop(self, iteratorVariables)
  elseif self:expectCurrentToken("Character", "=") then
    return consumeNumericLoop(self, iteratorVariables)
  end
end

return Statements