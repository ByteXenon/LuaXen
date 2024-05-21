--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-28
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local LuaExpressionEvaluator = require("Interpreter/LuaInterpreter/Parser/LuaMathParser/LuaExpressionEvaluator")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local insert = table.insert
local find = table.find or Helpers.tableFind

--* NodeFactory function assignments *--
local createExpressionNode     = NodeFactory.createExpressionNode
local createOperatorNode       = NodeFactory.createOperatorNode
local createUnaryOperatorNode  = NodeFactory.createUnaryOperatorNode
local createFunctionCallNode   = NodeFactory.createFunctionCallNode

--* Constants *--
local LUA_OPERATOR_PRECEDENCE = {
  Unary = {
    -- It really doesn't matter what the precedence of unary operators is,
    -- because they are always evaluated first.
    ["-"] = 10, ["#"] = 10, ["not"] = 10
  },
  Binary = {
    ["^"] = 9,
    ["*"] = 7, ["/"] = 7, ["%"] = 7,
    ["+"] = 6, ["-"] = 6,
    [".."] = 5,
    ["<"] = 4, ["<="] = 4, [">"] = 4, [">="] = 4,
    ["=="] = 3, ["~="] = 3,
    ["and"] = 2,
    ["or"] = 1
  },
  RightAssociative = {
    ["^"] = true,
    [".."] = true
  }
}

local LUA_UNARY_OPERATORS = LUA_OPERATOR_PRECEDENCE.Unary
local LUA_BINARY_OPERATORS = LUA_OPERATOR_PRECEDENCE.Binary
local LUA_RIGHT_ASSOCIATIVE_OPERATORS = LUA_OPERATOR_PRECEDENCE.RightAssociative

-- Normal math parsers have these constructors:
--  <Primary>, <Unary>, <Binary>, <Expression>
-- But Lua has more than that:
--  <Primary> = <Literal> | <Identifier> | <FunctionCall> | <ParenthesizedExpression> | etc.
--  <Suffix> = <FunctionCall> | <TableAccess>
--  <Prefix> = <Primary> <Suffix>*
--  <Unary> = <Prefix> | <UnaryOperator> <Unary>
--  <Binary> = <Unary> <BinaryOperator> <Binary>
--  <Expression> = <Binary>

--* LuaMathParserMethods *--
local LuaMathParserMethods = {}

--- (MAIN) Parses a Lua expression from the token stream.
-- @param <Table> previousExpression The previous expression node.
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:getExpression(previousExpression)
  self.previousExpression = previousExpression
  local expression = self:parseBinaryExpression(0)
  self.previousExpression = nil
  if not expression then
    self:consume(-1)
    return
  end

  local evaluated = LuaExpressionEvaluator.evaluate(expression)
  return createExpressionNode(evaluated)
end

--- Gets multiple expressions from the token stream.
-- @param <Number?> maxAmount The maximum amount of expressions to parse.
-- @param <Number?> maxReturnValueCount The maximum amount of return values for each expression.
-- @return <Table> expressions The parsed expressions.
function LuaMathParserMethods:getExpressions(maxAmount, maxReturnValueCount)
  local expressions = { self:getExpression() }

  -- If no expression was consumed, return the empty expressions table.
  if #expressions == 0 then return expressions end

  while self:compareTokenValueAndType(self:peek(), "Character", ",") do
    if maxAmount and #expressions >= maxAmount then break end
    self:consume(2) -- Consume the last token of the last expression and ","
    -- Consume the next expression
    insert(expressions, self:getExpression() )
  end

  return expressions
end

--// Input checkers //--

--- Checks if the given token is an unary operator.
-- @param <Table?> token=self.currentToken The token to check.
-- @return <Boolean> isUnaryOperator Whether the token is an unary operator.
function LuaMathParserMethods:isUnaryOperator(token)
  local token = token or self.currentToken
  return token and token.TYPE == "Operator" and LUA_UNARY_OPERATORS[token.Value]
end

--- Checks if the given token is a binary operator.
-- @param <Table?> token=self.currentToken The token to check.
-- @return <Boolean> isBinaryOperator Whether the token is a binary operator.
function LuaMathParserMethods:isBinaryOperator(token)
  local token = token or self.currentToken
  return token and token.TYPE == "Operator" and LUA_BINARY_OPERATORS[token.Value]
end

--- Checks if the given token is a right-associative (binary) operator.
-- @param <Table?> token=self.currentToken The token to check.
-- @return <Boolean> isRightAssociativeOperator Whether the token is a right-associative operator.
function LuaMathParserMethods:isRightAssociativeOperator(token)
  local token = token or self.currentToken
  return token and token.TYPE == "Operator" and LUA_RIGHT_ASSOCIATIVE_OPERATORS[token.Value]
end

--- Gets the precedence of the given (binary) operator. (Unary operators have no precedence.)
-- @param <Table?> token=self.currentToken The token to get the precedence of.
-- @return <Number> precedence The precedence of the operator.
function LuaMathParserMethods:getPrecedence(token)
  local token = token or self.currentToken
  return LUA_BINARY_OPERATORS[token.Value]
end

--// Parsers //--

--- Consumes primary expressions (e.g., literals, identifiers, etc.)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parsePrimaryExpression()
  local currentToken = self.currentToken
  local tokenType = currentToken.TYPE
  local tokenValue = currentToken.Value

  local previousExpression = self.previousExpression
  self.previousExpression = nil

  if previousExpression then
    return previousExpression
  end

  if tokenType == "Number" or tokenType == "String"
   or tokenType == "Constant" or tokenType == "VarArg" then
    return currentToken
  elseif tokenType == "Identifier" then
    local variableNode, variable = self:convertIdentifierToVariableNode(currentToken)
    if variable then
      insert(variable.References, variableNode)
    end
    return variableNode
  elseif tokenType == "Character" then
    if tokenValue == "(" then -- Parenthesized expression
      self:consume() -- Consume the parenthesis
      local oldExpectedReturnValueCount = self.expectedReturnValueCount
      self.expectedReturnValueCount = 1 -- Parenthesized expressions always return 1 value
      local expression = self:getExpression()
      self.expectedReturnValueCount = oldExpectedReturnValueCount

      self:consume() -- Consume the last char of the expression
      return expression
    elseif tokenValue == "{" then -- Table
      return self:consumeTable()
    end
  elseif tokenType == "Keyword" then
    if tokenValue == "function" then
      local oldExpectedReturnValueCount = self.expectedReturnValueCount
      self.expectedReturnValueCount = 0
      local functionNode = self:consumeFunction()
      self.expectedReturnValueCount = oldExpectedReturnValueCount
      return functionNode
    end
  end

  -- error("Unexpected token: " .. stringifyTable(currentToken))
  return nil
end

--- Consumes suffix expressions (e.g., function calls, table accesses, etc.)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseSuffixExpression(primaryExpression)
  -- suffixExpressions ::= [
  --  <expression> \( <args> \)
  --  || <expression> \. <identifier>
  --  || <expression> \: <identifier> \( <args> \)
  --  || <expression> \[ <expression> \]
  -- ]
  local currentTokenLine = self.currentToken.Line
  local nextToken = self:peek()
  local nextTokenLine = nextToken and nextToken.Line
  local nextTokenValue = nextToken and nextToken.Value
  if nextTokenValue == "(" then -- Function call
    if nextTokenLine ~= currentTokenLine then
      error("ambiguous syntax (function call x new statement)")
    end
    self:consume()
    -- <expression> \( <args> \)
    return self:parseFunctionCall(primaryExpression)
  elseif nextTokenValue == "." then -- Table access
    self:consume()
    -- <expression> \. <identifier>
    return self:consumeTableIndex(primaryExpression)
  elseif nextTokenValue == ":" then -- Method call
    self:consume()
    -- <expression> \: <identifier> \( <args> \)
    return self:consumeMethodCall(primaryExpression)
  elseif nextTokenValue == "[" then -- Bracket indexing
    self:consume()
    -- <expression> \[ <expression> \]
    return self:consumeBracketTableIndex(primaryExpression)
  elseif nextToken then
    -- In some edge cases, a user may call a function using only string,
    -- example: `print "Hello, World!"`. This is a valid Lua syntax.
    -- Let's handle both strings and tables here for that case.
    local nextTokenType = nextToken.TYPE
    if nextTokenType == "String" or (nextTokenValue == "{" and nextTokenType == "Character") then
      self:consume()
      return self:parseImplicitFunctionCall(primaryExpression)
    end
  end

  return nil
end

--- Consumes prefix expressions (e.g., primary expressions followed by suffix expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parsePrefixExpression()
  local primaryExpression = self:parsePrimaryExpression() -- <primary>
  if not primaryExpression then return end

  -- <suffix>*
  while (true) do
    local newExpression = self:parseSuffixExpression(primaryExpression)
    if not newExpression then break end
    primaryExpression = newExpression
  end

  return primaryExpression
end

--- Consumes unary expressions (e.g., unary operators followed by prefix expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseUnaryOperator()
  -- <unary> ::= <unary operator> <unary> | <primary>
  local unaryOperator = self.currentToken
  if not self:isUnaryOperator(unaryOperator) then
    -- <primary> fallback
    return self:parsePrefixExpression()
  end

  -- <unary operator> <unary>
  self:consume() -- Consume the operator
  local expression = self:parseUnaryOperator()
  return createUnaryOperatorNode(unaryOperator.Value, expression)
end

--- Consumes binary expressions (e.g., binary operators followed by unary expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseBinaryExpression(minPrecedence)
  -- <binary> ::= <unary> <binary operator> <binary> | <unary>
  local expression = self:parseUnaryOperator() -- <unary>
  if not expression then return end

  local operatorToken = self:peek()
  while self:isBinaryOperator(operatorToken) do
    local precedence = self:getPrecedence(operatorToken)
    if precedence <= minPrecedence and not self:isRightAssociativeOperator(operatorToken) then
      break
    end

    -- The <binary operator> <binary> part itself
    local nextToken = self:consume(2) -- Advance to and consume the operator
    if not nextToken then error("Unexpected end") end

    local right = self:parseBinaryExpression(precedence)
    if not right then error("Unexpected end") end

    expression = createOperatorNode(operatorToken.Value, expression, right)
    operatorToken = self:peek()
  end
  return expression
end

return LuaMathParserMethods