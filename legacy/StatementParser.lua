--[[
  Name: StatementParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-17
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/StatementParser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local insert = table.insert
local max = math.max
local find = table.find or Helpers.tableFind

--* NodeFactory functions imports *--
-- (I had to do this to make the code faster)
local createGroup                       = NodeFactory.createGroup -- (nodeList)
local createOperatorNode                = NodeFactory.createOperatorNode -- (operatorValue, leftExpr, rightExpr, precedence)
local createUnaryOperatorNode           = NodeFactory.createUnaryOperatorNode -- (operatorValue, operand, precedence)
local createFunctionCallNode            = NodeFactory.createFunctionCallNode -- (expression, arguments, expectedReturnValueCount)
local createMethodCallNode              = NodeFactory.createMethodCallNode -- (expression, arguments, expectedReturnValueCount)
local createIdentifierNode              = NodeFactory.createIdentifierNode -- (value)
local createNumberNode                  = NodeFactory.createNumberNode -- (value)
local createIndexNode                   = NodeFactory.createIndexNode -- (index, expression)
local createMethodIndexNode             = NodeFactory.createMethodIndexNode -- (index, expression)
local createTableNode                   = NodeFactory.createTableNode -- (elements)
local createTableElementNode            = NodeFactory.createTableElementNode -- (key, value, implicitKey)
local createFunctionNode                = NodeFactory.createFunctionNode -- (parameters, isVararg, codeBlock)
local createFunctionDeclarationNode     = NodeFactory.createFunctionDeclarationNode -- (parameters, isVararg, codeBlock, fields)
local createMethodDeclarationNode       = NodeFactory.createMethodDeclarationNode -- (parameters, isVararg, codeBlock, fields)
local createVariableAssignmentNode      = NodeFactory.createVariableAssignmentNode -- (variables, expressions, metadata)
local createLocalVariableAssignmentNode = NodeFactory.createLocalVariableAssignmentNode -- (variables, expressions, metadata)
local createLocalFunctionNode           = NodeFactory.createLocalFunctionNode -- (name, parameters, isVararg, codeBlock)
local createLocalVariableNode           = NodeFactory.createLocalVariableNode -- (value)
local createGlobalVariableNode          = NodeFactory.createGlobalVariableNode -- (value)
local createUpvalueNode                 = NodeFactory.createUpvalueNode -- (value, upvalueLevel)
local createIfStatementNode             = NodeFactory.createIfStatementNode -- (condition, codeBlock, elseIfs, elseStatement)
local createElseIfStatementNode         = NodeFactory.createElseIfStatementNode -- (condition, codeBlock)
local createElseStatementNode           = NodeFactory.createElseStatementNode -- (codeBlock)
local createUntilLoopNode               = NodeFactory.createUntilLoopNode -- (codeBlock, statement)
local createDoBlockNode                 = NodeFactory.createDoBlockNode -- (codeBlock)
local createWhileLoopNode               = NodeFactory.createWhileLoopNode -- (expression, codeBlock)
local createReturnStatementNode         = NodeFactory.createReturnStatementNode -- (expressions)
local createContinueStatementNode       = NodeFactory.createContinueStatementNode -- ()
local createBreakStatementNode          = NodeFactory.createBreakStatementNode -- ()
local createGenericForNode              = NodeFactory.createGenericForNode -- (iteratorVariables, expressions, codeBlock)
local createNumericForNode              = NodeFactory.createNumericForNode -- (iteratorVariables, expressions, codeBlock)

--* Statements *--
local Statements = {}

-- "<variable>(, <variable>)* (= <expression>(, <expression>)*)?"
function Statements:__VariableAssignment(variables)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(nil, #variables)

  return createVariableAssignmentNode(variables, expressions)
end

-- "[<identifier>, <vararg>]? [, <identifier>, <vararg>]*"
function Statements:__FunctionParameters()
  local parameters = {}
  local isVararg = false
  while true do
    local currentToken = self.currentToken
    local tokenType = currentToken.TYPE
    if tokenType == "Identifier" then
      insert(parameters, currentToken.Value)
    elseif tokenType == "VarArg" then
      -- insert(parameters, "...")
      isVararg = true
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

  return parameters, isVararg
end

-- function(<args>) <code_block> end
function Statements:consumeFunction()
  self:consume() -- Consume the "function" keyword
  self:expectCurrentToken("Character", "(")
  self:consume() -- Consume "("
  local parameters, isVararg = self:__FunctionParameters()
  self:expectCurrentToken("Character", ")")
  self:consume() -- Consume ")"
  local codeBlock = self:consumeCodeBlock({ "end" }, true, parameters)
  self:expectCurrentToken("Keyword", "end")

  -- self:consume()
  return createFunctionNode(parameters, isVararg, codeBlock)
end

-- <table>.<index>
function Statements:consumeTableIndex(currentExpression)
  self:consume() -- Consume the "." symbol

  local indexToken = self.currentToken
  if indexToken.TYPE == "Identifier" then
    indexToken.TYPE = "String"
  end
  return createIndexNode(indexToken, currentExpression)
end

-- <table>[<expression>]
function Statements:consumeBracketTableIndex(currentExpression)
  self:consume() -- Consume the "[" symbol
  local expression = self:getExpression()
  self:expectNextToken("Character", "]")
  return createIndexNode(expression, currentExpression)
end

-- <function_name>[<expression>]*
function Statements:consumeFunctionCall(currentExpression)
  -- Get arguments for the function
  if self.currentToken.TYPE == "Character" and self.currentToken.Value == "(" then
    self:consume() -- Consume the "(" symbol
    local arguments = {};
    if not self:isClosingParenthesis(self.currentToken) then
      arguments = self:getExpressions()
      self:consume()
    end
    self:expectCurrentToken("Character", ")")

    return createFunctionCallNode(currentExpression, arguments)
  elseif self.currentToken.TYPE == "String" or (self.currentToken.TYPE == "Character" and self.currentToken.Value == "{") then
    local argument = self:getExpression()
    return createFunctionCallNode(currentExpression, {argument})
  end
end

-- <table>:<method_name>(<args>*)
function Statements:consumeMethodCall(currentExpression)
  self:consume() -- Consume the ":" symbol
  local functionName = self.currentToken
  if functionName.TYPE ~= "Identifier" then
    return error("Incorrect function name")
  end
  functionName.TYPE = "String"
  self:consume() -- Consume the name of the method

  local functionCall = self:consumeFunctionCall(createMethodIndexNode(functionName, currentExpression))
  return createMethodCallNode(functionCall.Expression, functionCall.Arguments)
end

-- <identifier>
function Statements:convertIdentifierToVariableNode(token)
  local tokenValue = token.Value

  local variableType, upvalueIndex = self:getVariableType(tokenValue)
  if variableType == "Local" then
    return createLocalVariableNode(tokenValue)
  elseif variableType == "Global" then
    return createGlobalVariableNode(tokenValue)
  elseif variableType == "Upvalue" then
    return createUpvalueNode(tokenValue, upvalueIndex)
  end
end

-- Lvalue = <identifier> | (<table>[.<field>]*)
function Statements:consumeLvalue()
  local currentToken = self.currentToken
  if currentToken.TYPE ~= "Identifier" then
    return error("Expected an lvalue, but got " .. currentToken.TYPE)
  end

  local lvalue = self:convertIdentifierToVariableNode(currentToken)
  local nextToken = self:peek()
  while self:compareTokenValueAndType(nextToken, "Character", ".") or
        self:compareTokenValueAndType(nextToken, "Character", "[") do
    self:consume() -- Consume the identifier
    if self.currentToken.Value == "." then lvalue = self:consumeTableIndex(lvalue)
    else                                   lvalue = self:consumeBracketTableIndex(lvalue)
    end
    -- Optimisation
    nextToken = self:peek()
  end
  return lvalue
end

-- Lvalue = <identifier> | (<table>[.<field>]*)
-- <Lvalue> [, <Lvalue>]* = <expression> [, <expression>]*
function Statements:consumeLvalues(lvalue)
  local lvalues = { lvalue }
  local currentToken = self.currentToken -- Optimization
  while currentToken do
    insert(lvalues, self:consumeLvalue())
    currentToken = self:consume() -- Consume the last token of the last lvalue
    if not self:compareTokenValueAndType(currentToken, "Character", ",") then
      break
    end
    currentToken = self:consume() -- Consume ","
  end

  return lvalues
end

-- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
--                  | <lvalue> = <expression> [, <expression>]*
-- ^^^ I broke down the assignment into terms
-- (multiple lvalues vs single lvalue) so it'll be easier to parse
function Statements:parseAssignment(lvalue)
  local lvalues
  local nextToken = self:peek()

  -- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
  if self:compareTokenValueAndType(nextToken, "Character", ",") then
    self:consume() -- Consume the last token of the last lvalue
    self:consume() -- Consume ","
    return self:__VariableAssignment(lvalues)

  -- <assignment> ::= <lvalue> = <expression>
  elseif self:compareTokenValueAndType(nextToken, "Character", "=") then
    self:consume() -- Consume the last token of the last lvalue
    return self:__VariableAssignment({ lvalue })
  end

  return -- This is not an assignment
end

-- <functionCall> ::= \( <args> \)
function Statements:parseFunctionCall(lvalue)
  self:consume() -- Consume the "("
  local arguments = self:getExpressions()
  self:consume()
  return createFunctionCallNode(lvalue, arguments)
end

-- <code block> ::= (<statement> | <function call> | <assignment>)*
function Statements:parseFunctionCallOrAssignment()
  local lvalue
  if self.currentToken.TYPE == "Identifier" then
    lvalue = self:consumeLvalue()
    local assignment = self:parseAssignment(lvalue)
    if assignment then
      return assignment
    end
  end

  -- OK, we just parse an expression and hope it's a function call
  return self:getExpression(lvalue)
end

-- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , | ; )? }*
function Statements:consumeTable()
  -- Table constructor
  -- \{ [
  --  \[ <expression> \] = <expression>
  --  || <identifier> = <expression>
  --  || <expression>
  -- ]* \}
  self:consume() -- Consume "{"

  local elements = {}
  local internalImplicitKey = 1

  -- Consume table elements
  while not self:compareTokenValueAndType(self.currentToken, "Character", "}") do
    local curToken = self.currentToken
    local key, value
    local isImplicitKey = false

    if self:compareTokenValueAndType(curToken, "Character", "[") then
      -- [<expression>] = <expression>
      self:consume() -- Consume "["
      key = self:getExpression()
      self:expectNextToken("Character", "]")
      self:expectNextToken("Character", "=")
      self:consume() -- Consume "="
      value = self:getExpression()
    elseif curToken.TYPE == "Identifier" and self:compareTokenValueAndType(self:peek(), "Character", "=") then
      -- <identifier> = <expression>
      key = curToken
      -- Convert identifier to string because it's not a variable
      key.TYPE = "String"
      self:consume() -- Consume key
      self:consume() -- Consume "="
      value = self:getExpression()
      insert(elements, createTableElementNode(key, value))
    else -- <expression>
      key = createNumberNode(internalImplicitKey)
      value = self:getExpression()
      isImplicitKey = true
      internalImplicitKey = internalImplicitKey + 1
    end
    insert(elements, createTableElementNode(key, value, isImplicitKey))

    self:consume() -- Consume the last token of the expression
    local shouldContinue = (self.currentToken.TYPE == "Character") and
                            (self.currentToken.Value == "," or self.currentToken.Value == ";")
    if not shouldContinue then break end
    self:consume()
  end

  return createTableNode(elements)
end

function Statements:handleSpecialOperators(token, leftExpr)
  if token.TYPE == "Character" then
    -- <table>.<index>
    if token.Value == "." then return self:consumeTableIndex(leftExpr)
    -- <table>[<expression>]
    elseif token.Value == "[" then return self:consumeBracketTableIndex(leftExpr)
    -- <table>:<method_name>(<args>*)
    elseif token.Value == ":" then return self:consumeMethodCall(leftExpr)
    end
  end
  return self:consumeFunctionCall(leftExpr)
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
  self:registerVariable(functionName)
  self:consume()
  self:expectCurrentTokenAndConsume("Character", "(")
  local parameters, isVararg = self:__FunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"}, true, parameters)

  return createLocalFunctionNode(functionName, parameters, isVararg, codeBlock)
end

-- "local <identifier>(, <identifier>)* (= <expression>(, <expression>)*)?" |
-- "local function <identifier>(<args>) <code_block> end"
function Statements:_local()
  if self:compareTokenValueAndType(self:peek(), "Keyword", "function") then
    return self:_localFunction()
  end
  self:consume() -- Consume "local"
  local variables = self:getMultipleIdentifiers(true)
  self:consume() -- Consume the last identifier

  if not self:compareTokenValueAndType(self.currentToken, "Character", "=") then
    self:consume(-1)
    return createLocalVariableAssignmentNode(variables)
  end

  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(nil, #variables)
  for _, identifierNode in ipairs(variables) do
    self:registerVariable(identifierNode.Value)
  end
  return createLocalVariableAssignmentNode(variables, expressions)
end

-- "if <expression> then <codeblock>( elseif <expression> then <codeblock>)*( else <codeblock>)? end"
function Statements:_if()
  self:consume() -- Consume "if"

  local expression = self:getExpression()
  self:expectNextTokenAndConsume("Keyword", "then")
  local ifStatementCodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
  local newIfStatement = createIfStatementNode(expression, ifStatementCodeBlock, {})

  -- Consume multiple "elseif" statements if there's any
  while self:compareTokenValueAndType(self.currentToken, "Keyword", "elseif") do
    self:consume() -- Consume "elseif"
    local elseIfCondition = self:getExpression()
    self:expectNextTokenAndConsume("Keyword", "then")
    local elseIfCodeBlock = self:consumeCodeBlock({"end", "else", "elseif"})
    insert(newIfStatement.ElseIfs, createElseIfStatementNode(elseIfCondition, elseIfCodeBlock))
  end
  -- Consume an optional "else" statement
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
    self:consume() -- Consume "else"
    local elseCodeBlock = self:consumeCodeBlock({"end"})
    newIfStatement.Else = createElseStatementNode(elseCodeBlock)
  end

  return newIfStatement
end

-- "repeat <codeblock> until <expression>"
function Statements:_repeat()
  self:consume() -- Consume "repeat"
  local codeBlock = self:consumeCodeBlock({"until"})
  self:expectCurrentTokenAndConsume("Keyword", "until")
  local statement = self:getExpression()

  return createUntilLoopNode(codeBlock, statement)
end

-- "do <code_block> end"
function Statements:_do()
  self:consume() -- Consume "do"
  local codeBlock = self:consumeCodeBlock({"end"})

  return createDoBlockNode(codeBlock)
end

-- "while <expression> do <code_block> end"
function Statements:_while()
  self:consume() -- Consume "while"
  local expression = self:getExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock({"end"})

  return createWhileLoopNode(expression, codeBlock)
end

-- "return( <expression>(, <expression>)*)?"
function Statements:_return()
  self:consume() -- Consume "return"
  local expressions = self:getExpressions()

  return createReturnStatementNode(expressions)
end

-- "break"
function Statements:_break()
  return createBreakStatementNode()
end

-- "continue"
function Statements:_continue()
  return createContinueStatementNode()
end

-- ":<identifier>(<args>) <code_block> end"
function Statements:_method(fields)
  self:consume() -- Consume ":"
  local methodName = self:expectCurrentToken("Identifier")
  insert(fields, methodName.Value)
  self:consume() -- Consume method name

  self:expectCurrentTokenAndConsume("Character", "(")
  local parameters, isVararg = self:__FunctionParameters()
  insert(parameters, "self")
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"}, true, parameters)

  parameters[#parameters] = nil -- Remove "self"
  return createMethodDeclarationNode(parameters, isVararg, codeBlock, fields)
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
  local parameters, isVararg = self:__FunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"}, true, parameters)

  return createFunctionDeclarationNode(parameters, isVararg, codeBlock, fields)
end

-- "in <expression> do <codeblock> end"
local function consumeGenericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Keyword", "in")
  local expressions = self:getExpressions()
  self:expectNextTokenAndConsume("Keyword", "do")
  self:registerVariables(iteratorVariables)
  local codeBlock = self:consumeCodeBlock({"end"})

  return createGenericForNode(iteratorVariables, expressions, codeBlock)
end

-- "= <expression>, <expression>(, <expression>)? do <codeblock> end"
local function consumeNumericLoop(self, iteratorVariables)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(3)
  self:expectNextTokenAndConsume("Keyword", "do")
  self:registerVariables(iteratorVariables)
  local codeBlock = self:consumeCodeBlock({"end"})

  return createNumericForNode(iteratorVariables, expressions, codeBlock)
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