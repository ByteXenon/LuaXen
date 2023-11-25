--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--! DOESNT WORK

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
local rightAssociativeOperators = { "^", ".." }
local operandTypes = {"String", "Number", "Identifier", "Constant"}
local operatorPrecedences = {
  unary = {
    ["-"] = 8, ["#"] = 8, ["not"] = 8
  },
  binary = {
    ["."] = 10, [":"] = 10, ["[]"] = 10,
    
    ["("] = 9,

    -- Arithmetic operations
    ["^"] = 7,
    ["*"] = 6, ["/"] = 6, ["%"] = 6,
    ["+"] = 5, ["-"] = 5,
    
    -- String concatenation
    [".."] = 4,

    -- Comparison operations
    ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["=="] = 3, ["~="] = 3,
    
    -- Logical operations
    ["and"] = 2,
    ["or"] = 1
  }
}

--* LuaMathParserMethods *--
local LuaMathParserMethods = {}

function LuaMathParserMethods:isOperand(token)
  local tokenType = token.TYPE
  return find(operandTypes, tokenType)
end

function LuaMathParserMethods:isRightAssociative(operator)
  return find(rightAssociativeOperators, operator)
end

function LuaMathParserMethods:isSpecialOperator(token)
  return token.Value == "." or token.Value == ":" or token.Value == "[" or token.Value == "("
end

function LuaMathParserMethods:getPrecedence(token)
  return self.operatorPrecedences.binary[token and token.Value]
end

function LuaMathParserMethods:handleOperatorWithPrecedence(token, precedence, left, minPrecedence)
  local nextPrecedence = (self:isRightAssociative(token.Value) and precedence - 1) or precedence
  self:consume()

  local right = self:parseBinaryOperator(nextPrecedence)
  if not right then return end
  return createOperatorNode(token.Value, left, right, precedence)
end

function LuaMathParserMethods:parseBinaryOperator(minPrecedence)
  local currentToken = self.currentToken
  if not currentToken then
    return error("Unexpected end of the expression")
  end

  local left = self:parseUnaryOperator()
  if not left then
    self.unexpectedEnd = true
    self.currentTokenIndex = self.currentTokenIndex - 1
    return
  end

  while true do
    local token = self.currentToken
    if self:isClosingParenthesis(token) and self.isInParentheses then
      self.unexpectedEnd = true
      break
    end

    if not token or self:isClosingParenthesis(token) then
      self.unexpectedEnd = true
      break
    end

    local precedence = self:getPrecedence(token)
    if self:isSpecialOperator(token) then
      local newLeft = self:handleSpecialOperators(token, left)
      if not newLeft then
        self.unexpectedEnd = true
        return left
      end

      left = newLeft
      self:consume() -- Consume the last character of an operator
    elseif precedence then
      if precedence <= minPrecedence then break end
      local newLeft = self:handleOperatorWithPrecedence(token, precedence, left, minPrecedence) 
      if not newLeft then
        self.unexpectedEnd = true
        return
      end
      left = newLeft
    else
      self.unexpectedEnd = true;
      return left
    end
  end

  return left
end;

function LuaMathParserMethods:parseUnaryOperator()
  local token = self.currentToken

  if not token then
    return error("Unexpected end of the expression")
  end

  local value = token.Value
  local TYPE = token.TYPE
  if TYPE == "Operator" then
    if self.operatorPrecedences.unary[value] then
      self:consume()
      local operand = self:parseUnaryOperator()
      return createUnaryOperatorNode(token.Value, operand, precedence)
    end
  elseif TYPE == "Character" and (value == "(" or value == ")") then
    if value == "(" then
      self:consume()
      self.isInParentheses = true
      local expression = self:parseBinaryOperator(0)
      local currentToken = self.currentToken
      if not currentToken or not self:isClosingParenthesis(currentToken) then
        return error("Mismatched parentheses")
      end
      self.isInParentheses = false
      self:consume()
      return expression
    elseif value == ")" then
      if not errorOnFail then
        self.unexpectedEnd = true;
        return
      end

      return error("Unexpected closing parenthesis")
    end
  elseif self:isOperand(token) then
    self:consume()
    return token
  else
    local operand = self:handleSpecialOperands(token)
    self:consume() -- Consume the last character of an operand

    if operand then return operand end
  end

  if not errorOnFail then
    self.unexpectedEnd = true;
    self.errorMessage = "Unexpected token: " .. stringifyTable(token)
    return
  end

  return error(errorMessage)
end;

-- Main (Public)
function LuaMathParserMethods:parseExpression()
  self.unexpectedEnd = false
  self.errorMessage = nil

  local expression = self:parseBinaryOperator(0)
  self.currentTokenIndex = self.currentTokenIndex - ((self.unexpectedEnd and 1) or 0)
  self.currentToken = self.tokens[self.currentTokenIndex]

  if expression then return createExpressionNode(expression) end
  return expression
end;

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:new()
  local LuaMathParserInstance = {}
  LuaMathParserInstance.errorOnFail = false
  LuaMathParserInstance.operatorPrecedences = operatorPrecedences

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