--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/LuaMathParser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Parser/Parser")
local Debugger = ModuleManager:loadModule("Debugger/Debugger")
local NodeFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind

--* NodeFactory function assignments *--
local createOperatorNode      = NodeFactory.createOperatorNode
local createUnaryOperatorNode = NodeFactory.createUnaryOperatorNode
local createExpressionNode    = NodeFactory.createExpressionNode

--* Constants *--
local EOF_TOKEN = { TYPE = "EOF" }
local RIGHT_ASSOCIATIVE_OPERATORS = { "^", ".." }
local OPERAND_TYPES = {"String", "Number", "Identifier", "Constant"}
local LUA_OPERATOR_PRECEDENCES = {
  unary = {
    ["-"] = 8, ["#"] = 8, ["not"] = 8
  },
  binary = {
    ["."] = 9, ["["] = 9, -- Table index nodes 
    [":"] = 9, -- Method call node 
    ["("] = 9, -- Function call node

    ["^"] = 7,
    ["*"] = 6, ["/"] = 6, ["%"] = 6,
    ["+"] = 5, ["-"] = 5,
    [".."] = 4,
    ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["=="] = 3, ["~="] = 3,
    ["and"] = 2,
    ["or"] = 1
  }
}

--* LuaMathParserMethods *--
local LuaMathParserMethods = {}

function LuaMathParserMethods:getCurrentToken()
  return self.tokens[self.currentTokenIndex] or EOF_TOKEN
end
function LuaMathParserMethods:peek(n)
  return self.tokens[self.currentTokenIndex + (n or 1)] or EOF_TOKEN
end
function LuaMathParserMethods:consumeToken()
  self.currentTokenIndex = self.currentTokenIndex + (n or 1)
end

function LuaMathParserMethods:getPrecedence(token)
  return LUA_OPERATOR_PRECEDENCES.binary[token and token.Value]
end

function LuaMathParserMethods:syncLuaParser()
  self.luaParser.currentTokenIndex = self.currentTokenIndex -- ((self.unexpectedEnd and 1) or -1)
  self.luaParser.currentToken = self.luaParser.tokens[self.luaParser.currentTokenIndex] or EOF_TOKEN
end
function LuaMathParserMethods:syncMathParser()
  self.tokens = self.luaParser.tokens -- Just in case
  self.currentTokenIndex = self.luaParser.currentTokenIndex
end

function LuaMathParserMethods:isClosingParenthesis(token)
  return token.TYPE == "Character" and token.Value == ")"
end
function LuaMathParserMethods:isOperand(token)
  local tokenType = token.TYPE
  return find(OPERAND_TYPES, tokenType)
end
function LuaMathParserMethods:isRightAssociative(operator)
  return find(RIGHT_ASSOCIATIVE_OPERATORS, operator)
end

function LuaMathParserMethods:handleOperatorWithPrecedence(token, precedence, left)
  if precedence == 9 then
    local tokenValue = token.Value
    if tokenValue == "(" then -- FunctionCall 
      self:syncLuaParser()
      local right = self.luaParser:consumeFunctionCall(left)
      self:syncMathParser()
      self:consumeToken()
      return right
    elseif tokenValue == "." or tokenValue == "[" then -- TableIndex
      self:syncLuaParser()
      local indexNode = self.luaParser:_TableIndex(left)
      self:syncMathParser()
      self:consumeToken()

      return indexNode
    elseif tokenValue == ":" then -- MethodCall
      self:syncLuaParser()
      local methodCallNode = self.luaParser:consumeMethodCall(left)
      self:syncMathParser()
      self:consumeToken()

      return methodCallNode
    else
      return error(tokenValue)
    end
  end

  local nextPrecedence = (self:isRightAssociative(token.Value) and precedence - 1) or precedence

  self:consumeToken()
  local right = self:parseBinaryOperator(nextPrecedence)
  if not right then return end
  return createOperatorNode(token.Value, left, right, precedence)
end
function LuaMathParserMethods:handleSpecialOperators(token, leftExpr)
  self:syncLuaParser()
  local newLeft = self.luaParser:handleSpecialOperators(token, leftExpr)
  self:syncMathParser()
  return newLeft
end

function LuaMathParserMethods:parseBinaryOperator(minPrecedence)
  local currentToken = self:getCurrentToken()
  if not currentToken or currentToken.TYPE == "EOF" then
    return error("Unexpected end of the expression")
  end

  local left = self:parseUnaryOperator()
  if not left then
    self.unexpectedEnd = true
    self.currentTokenIndex = self.currentTokenIndex - 1
    return
  end

  while true do
    local token = self:getCurrentToken()
    if self:isClosingParenthesis(token) and self.isInParentheses then break end
    if not token or self:isClosingParenthesis(token) then
      self.unexpectedEnd = true
      break
    end

    local precedence = self:getPrecedence(token)
    if precedence then
      if precedence <= minPrecedence then break end
      local newLeft = self:handleOperatorWithPrecedence(token, precedence, left) 
      if not newLeft then
        self.unexpectedEnd = true
        return
      end
      left = newLeft
    elseif not precedence then
      local newLeft = self:handleSpecialOperators(token, left)
      if not newLeft then
        self.unexpectedEnd = true
        return left
      end

      left = newLeft
      self:consumeToken() -- Consume the last character of an operator
    end
  end

  return left
end
function LuaMathParserMethods:parseUnaryOperator()
  local token = self:getCurrentToken()

  if not token then
    return error("Unexpected end of the expression")
  end

  local value = token.Value
  local TYPE = token.TYPE
  if TYPE == "Operator" then
    if LUA_OPERATOR_PRECEDENCES.unary[value] then
      self:consumeToken()
      local operand = self:parseUnaryOperator()
      return createUnaryOperatorNode(token.Value, operand, precedence)
    end
  elseif TYPE == "Character" and (value == "(" or value == ")") then
    if value == "(" then
      self:consumeToken()
      self.isInParentheses = true
      local expression = self:parseBinaryOperator(0)
      local currentToken = self:getCurrentToken()
      if not currentToken or not self:isClosingParenthesis(currentToken) then
        return error("Mismatched parentheses")
      end
      self.isInParentheses = false
      self:consumeToken()
      return expression
    elseif value == ")" then
      if not errorOnFail then
        self.unexpectedEnd = true
        return
      end

      return error("Unexpected closing parenthesis")
    end
  elseif self:isOperand(token) then
    self:consumeToken()
    return token
  else
    self:syncLuaParser()
    local operand = self.luaParser:handleSpecialOperands(token)
    self:syncMathParser()
    self:consumeToken() -- Consume the last character of an operand

    if operand then
      return operand
    end
  end

  local errorMessage = "Unexpected token: " .. stringifyTable(token)
  if not errorOnFail then
    self.unexpectedEnd = true
    self.errorMessage = errorMessage
    return
  end

  return error(errorMessage)
end

-- Main (public)
function LuaMathParserMethods:parse()
  local expression = self:parseBinaryOperator(0)
  self.luaParser.currentTokenIndex = self.currentTokenIndex - ((self.unexpectedEnd and 1) or 0)
  self.luaParser.currentToken = self.luaParser.tokens[self.luaParser.currentTokenIndex]

  if expression then
    return createExpressionNode(expression)
  end
  return expression
end

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:getExpression(luaParser, tokens, startIndex, errorOnFail)
  local LuaMathParserInstance = {}
  LuaMathParserInstance.errorOnFail = false
  LuaMathParserInstance.luaParser = luaParser
  LuaMathParserInstance.tokens = tokens
  LuaMathParserInstance.currentTokenIndex = startIndex
  LuaMathParserInstance.currentToken = (tokens[startIndex] or EOF_TOKEN)

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if LuaMathParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and LuaMathParserInstance: " .. index)
      end
      LuaMathParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("LuaMathParserMethods", LuaMathParserMethods, true)

  local result = LuaMathParserInstance:parse()
  return result
end

return LuaMathParser