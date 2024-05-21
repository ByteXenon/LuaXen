--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Dependencies *--

local Helpers = require("Helpers/Helpers")

local MathParser = require("Interpreter/LuaInterpreter/MathParser/Parser/Parser")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Export library functions *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind

--* NodeFactory function assignments *--
local createOperatorNode      = NodeFactory.createOperatorNode
local createUnaryOperatorNode = NodeFactory.createUnaryOperatorNode
local createExpressionNode    = NodeFactory.createExpressionNode
local createFunctionCallNode  = NodeFactory.createFunctionCallNode

--* LuaMathParserMethods *--
local LuaMathParserMethods = {}

function LuaMathParserMethods:getExpression()
  local result = self:parseOrExpression()
  if not result then
    -- If the result is nil, it means that the expression is empty
    -- And we consumed a non-expression token, so we need to revert one token back.
    self:consume(-1)
    return
  end
  return createExpressionNode(result)
end

function LuaMathParserMethods:parseBaseExpression()
  local token = self.currentToken
  local tokenType = token.TYPE

  -- Token -> Expression<Node> conversion
  if tokenType == "Identifier" or tokenType == "Number"
   or tokenType == "String" or tokenType == "Constant" then
    return token
  -- Function
  elseif tokenType == "Keyword" and token.Value == "function" then
    return self:consumeFunction()
  -- Table
  elseif tokenType == "Character" and token.Value == "{" then
    return self:consumeTable()
  -- Parentheses
  elseif tokenType == "Character" and token.Value == "(" then
    self:consume() -- Skip the opening parenthesis
    local expr = self:parseOrExpression()
    self:consume() -- Skip the last character of the expression
    if not self:isClosingParenthesis(self.currentToken) then
      return error("Expected closing parenthesis, got: " .. stringifyTable(self.currentToken))
    end

    return expr
  end

  return nil
end

function LuaMathParserMethods:parsePrimaryExpression()
  local expr = self:parseBaseExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle function calls, method calls, and indexing
  while true do
    local nextTokenValue = nextToken.Value
    local nextTokenType = nextToken.TYPE
    if nextTokenType == "Character" and nextTokenValue == "(" then
      -- It's a function call
      -- "<expression>(<args>)"
      self:consume()
      expr = self:consumeFunctionCall(expr)
    elseif nextTokenType == "Character" and nextTokenValue == ":" then
      -- It's a method call
      -- "<expression>:(<args>)"
      self:consume()
      expr = self:consumeMethodCall(expr)
    elseif nextTokenType == "Character" and nextTokenValue == "[" then
      -- It's a bracket indexing operation
      -- "<expression>[<expression>]"
      self:consume()
      expr = self:consumeBracketTableIndex(expr)
    elseif nextTokenType == "Character" and nextTokenValue == "." then
      -- It's an indexing operation
      -- "<expression>.<identifier>"
      self:consume()
      expr = self:consumeTableIndex(expr)
    else
      -- A really special and specific case for function
      -- calls that are being called without using parentheses
      -- Example: `print"hello, world!"`
      while true do
        if (nextTokenType == "String" or (nextTokenType == "Character" and nextTokenValue == "{")) then
          self:consume()
          local functionCallArgument;
          if nextTokenType == "Character" and nextTokenValue == "{" then
            functionCallArgument = self:consumeTable()
          elseif nextTokenType == "String" then
            functionCallArgument = nextToken
          end
          expr = createFunctionCallNode(expr, {functionCallArgument})

          -- "nextToken" variable is just an optimization.
          nextToken = self:peek()
          nextTokenType = nextToken.TYPE
          nextTokenValue = nextToken.Value
        else
          break
        end
      end
      break
    end

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseUnaryExpression()
  local currentToken = self.currentToken
  local expr

  while (currentToken.TYPE == "Operator" and (currentToken.Value == "-" or currentToken.Value == "#" or currentToken.Value == "not")) do
    self:consume()
    local expression = self:parseUnaryExpression()
    expr = createUnaryOperatorNode(currentToken.Value, expression, 1)
    currentToken = self.currentToken
  end
  if not expr then
    expr = self:parsePrimaryExpression()
    if not expr then return nil end
  end

  return expr
end

function LuaMathParserMethods:parseExponentiationExpression()
  local expr = self:parseUnaryExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle exponentiation
  while nextToken.TYPE == "Operator" and nextToken.Value == "^" do
    self:consume(2)
    local operator = nextToken
    -- Exponentiation is right associative, stay at the same precedence level
    local right = self:parseExponentiationExpression()
    expr = createOperatorNode(operator.Value, expr, right, 2)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseMultiplicativeExpression()
  local expr = self:parseExponentiationExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle multiplication, division, and modulo
  while nextToken.TYPE == "Operator" and (nextToken.Value == "*" or nextToken.Value == "/" or nextToken.Value == "%") do
    self:consume(2)
    local operator = nextToken
    local right = self:parseExponentiationExpression()
    expr = createOperatorNode(operator.Value, expr, right, 3)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseAdditiveExpression()
  local expr = self:parseMultiplicativeExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle addition and subtraction
  while nextToken.TYPE == "Operator" and (nextToken.Value == "+" or nextToken.Value == "-") do
    self:consume(2) -- Skip the last character of the left expression and the operator
    local operator = nextToken
    local right = self:parseMultiplicativeExpression()
    expr = createOperatorNode(operator.Value, expr, right, 4)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseConcatenationExpression()
  local expr = self:parseAdditiveExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle string concatenation
  while nextToken.TYPE == "Operator" and nextToken.Value == ".." do
    self:consume(2)
    -- Concatenation is right associative, stay at the same precedence level
    local right = self:parseConcatenationExpression()
    expr = createOperatorNode("..", expr, right, 5)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseComparisonExpression()
  local expr = self:parseConcatenationExpression()
  if not expr then return nil end

  local nextToken = self:peek()
  local operators = {
    "<", ">", "<=", ">=", "==", "~="
  }

  -- Handle comparison operators
  while nextToken.TYPE == "Operator" and find(operators, nextToken.Value) do
    self:consume(2)
    local operator = nextToken
    local right = self:parseConcatenationExpression()
    expr = createOperatorNode(nextToken.Value, expr, right, 6)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseAndExpression()
  local expr = self:parseComparisonExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle logical AND
  while (nextToken.TYPE == "Operator" and nextToken.Value == "and" ) do
    self:consume(2)
    local right = self:parseComparisonExpression()
    expr = createOperatorNode("and", expr, right, 7)

    nextToken = self:peek()
  end

  return expr
end

function LuaMathParserMethods:parseOrExpression()
  local expr = self:parseAndExpression()
  if not expr then return nil end

  local nextToken = self:peek()

  -- Handle logical OR
  while (nextToken.TYPE == "Operator" and nextToken.Value == "or") do
    self:consume(2)
    local right = self:parseAndExpression()
    expr = createOperatorNode("or", expr, right, 8)

    nextToken = self:peek()
  end

  return expr
end

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:new()
  local LuaMathParserInstance = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if LuaMathParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and LuaMathParserInstance: " .. index)
      end
      LuaMathParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("LuaMathParserMethods", LuaMathParserMethods)

  return LuaMathParserInstance
end

return LuaMathParser