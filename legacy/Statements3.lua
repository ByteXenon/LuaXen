--[[
  Name: Statements.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-30
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local insert = table.insert
local max = math.max
local find = table.find or Helpers.tableFind

--* NodeFactory functions imports *--
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
function Statements:consumeVariableAssignment(lvalues, variables)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(nil, #lvalues)

  local variableAssignmentNode = createVariableAssignmentNode(lvalues, expressions)
  for _, variable in ipairs(variables) do
    if variable.TYPE == "Global" then
      insert(variable.DeclarationNodes, variableAssignmentNode)
    end
  end
  return variableAssignmentNode
end

-- "[<identifier>, <vararg>]? [, <identifier>, <vararg>]*"
function Statements:consumeFunctionParameters()
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

  local variables = {}
  for _, parameter in ipairs(parameters) do
    insert(variables, self:registerVariable(parameter))
  end
  return parameters, isVararg, variables
end

-- function(<args>) <code_block> end
function Statements:consumeFunction()
  self:consume() -- Consume the "function" keyword
  self:expectCurrentToken("Character", "(")
  self:consume() -- Consume "("
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  self:expectCurrentToken("Character", ")")
  self:consume() -- Consume ")"
  local codeBlock = self:consumeCodeBlock({ "end" }, nil, true)
  self:expectCurrentToken("Keyword", "end")
  self:popScope() -- Pop function scope

  -- self:consume()
  local functionNode = createFunctionNode(parameters, isVararg, codeBlock)
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = functionNode
  end
  return functionNode
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
    local arguments = {}
    if not (self.currentToken.Value == ")" and self.currentToken.TYPE == "Character") then
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
  return createMethodCallNode(functionCall.Expression, functionCall.Arguments, self.ExpectedReturnValueCount)
end

-- <identifier> [ \, <identifier> ]*
function Statements:consumeMultipleIdentifiers(self, oneOrMore)
  local identifiers = { }
  local currentToken = self.currentToken
  if currentToken.TYPE ~= "Identifier" then
    assert(not oneOrMore, "Expected an identifier, got: " .. stringifyTable(currentToken))
    return identifiers
  end
  insert(identifiers, currentToken.Value)

  while self:compareTokenValueAndType(self:peek(), "Character", ",") do
    self:consume(2) -- Consume the last identifier and ","
    local nextToken = self.currentToken
    if nextToken.TYPE ~= "Identifier" then
      return error("Expected an identifier, got: " .. stringifyTable(nextToken))
    end
    insert(identifiers, nextToken.Value)
  end

  return identifiers
end

-- Lvalue = <identifier> | (<table>[.<field>]*)
function Statements:consumeLvalue()
  local currentToken = self.currentToken
  if currentToken.TYPE ~= "Identifier" then
    return error("Expected an lvalue, but got " .. currentToken.TYPE)
  end

  local lvalue, variable = self:convertIdentifierToVariableNode(currentToken)
  local newLvalue = lvalue
  local nextToken = self:peek()
  while self:compareTokenValueAndType(nextToken, "Character", ".") or
        self:compareTokenValueAndType(nextToken, "Character", "[") do
    self:consume() -- Consume the identifier
    if self.currentToken.Value == "." then
      local node = self:consumeTableIndex(newLvalue)
      newLvalue = node
    else
      local node = self:consumeBracketTableIndex(newLvalue)
      newLvalue = node
    end
    -- Optimisation
    nextToken = self:peek()
  end
  if variable and variable.TYPE == "Local" then
    insert(variable.References, lvalue)
  end

  return newLvalue, variable
end

-- Lvalue = <identifier> | (<table>[.<field>]*)
-- <Lvalue> [, <Lvalue>]* = <expression> [, <expression>]*
function Statements:consumeLvalues(lvalue)
  local lvalues = { lvalue }
  local variables = {}
  local currentToken = self.currentToken -- Optimization
  while currentToken do
    local lvalue, variable = self:consumeLvalue()
    if variable then
      insert(variables, lvalue)
    end
    insert(lvalues, lvalue)
    currentToken = self:consume() -- Consume the last token of the last lvalue
    if not self:compareTokenValueAndType(currentToken, "Character", ",") then
      break
    end
    currentToken = self:consume() -- Consume ","
  end

  return lvalues, variables
end

-- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
--                  | <lvalue> = <expression> [, <expression>]*
-- ^^^ I broke down the assignment into terms
-- (multiple lvalues vs single lvalue) so it'll be easier to parse
function Statements:parseAssignment(lvalue, variable)
  local nextToken = self:peek()

  -- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
  if self:compareTokenValueAndType(nextToken, "Character", ",") then
    self:consume() -- Consume the last token of the last lvalue
    self:consume() -- Consume ","
    local lvalues, variables = self:consumeLvalues(lvalue)
    if variable then
      insert(variables, 1, variable)
    end
    return self:consumeVariableAssignment(lvalues, variables)

  -- <assignment> ::= <lvalue> = <expression>
  elseif self:compareTokenValueAndType(nextToken, "Character", "=") then
    self:consume() -- Consume the last token of the last lvalue
    return self:consumeVariableAssignment({ lvalue }, { variable })
  end

  return -- This is not an assignment
end

-- <functionCall> ::= \( <args> \)
function Statements:parseFunctionCall(lvalue)
  self:consume() -- Consume the "("
  local arguments = self:getExpressions()
  self:consume() -- Consume the last token of the expression
  return createFunctionCallNode(lvalue, arguments, self.expectedReturnValueCount)
end

-- <functionCall> ::= <string> | <table>
function Statements:parseImplicitFunctionCall(lvalue)
  local currentToken = self.currentToken
  local currentTokenType = currentToken.TYPE

  if currentTokenType == "String" then
    return createFunctionCallNode(lvalue, { currentToken }, self.expectedReturnValueCount)
  elseif currentTokenType == "Character" and currentToken.Value == "{" then
    return createFunctionCallNode(lvalue, { self:consumeTable() }, self.expectedReturnValueCount)
  end
  return nil
end

-- <code block> ::= (<statement> | <function call> | <assignment>)*
function Statements:parseFunctionCallOrAssignment()
  local lvalue, variable
  if self.currentToken.TYPE == "Identifier" then
    lvalue, variable = self:getExpression()
    local assignment = self:parseAssignment(lvalue, variable)
    if assignment then return assignment
    else
      if lvalue.TYPE == "Index" then
        insert(variable.References, lvalue.Expression)
      elseif lvalue.TYPE == "Variable" then
        insert(variable.References, lvalue)
      end
    end
  end

  -- OK, we just parse an expression and hope it's a function call
  return self:getExpression(lvalue)--.Value
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

-- "local function <identifier>(<args>) <code_block> end"
function Statements:consumeLocalFunction()
  self:consume() -- Consume "local"
  self:expectCurrentTokenAndConsume("Keyword", "function") -- Consume "function"
  local functionName = self:expectCurrentToken("Identifier").Value
  local variable = self:registerVariable(functionName)
  self:consume()
  self:expectCurrentTokenAndConsume("Character", "(")
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"}, nil, true)
  self:popScope() -- Pop function scope
  local functionNode = createLocalFunctionNode(functionName, parameters, isVararg, codeBlock)
  variable.DeclarationNode = functionNode
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = functionNode
  end

  return functionNode
end

-- ":<identifier>(<args>) <code_block> end"
function Statements:consumeMethod(expression, fields)
  self:consume() -- Consume ":"
  local methodName = self:expectCurrentToken("Identifier")
  insert(fields, methodName.Value)
  self:consume() -- Consume method name

  self:expectCurrentTokenAndConsume("Character", "(")
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  insert(parameters, "self")
  insert(variables, self:registerVariable("self"))
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock({"end"}, nil, true)
  self:popScope() -- Function scope

  parameters[#parameters] = nil -- Remove "self"
  local methodDeclarationNode = createMethodDeclarationNode(parameters, isVararg, codeBlock, expression, fields)
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = methodDeclarationNode
  end
  return methodDeclarationNode
end

return Statements