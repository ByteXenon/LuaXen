--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/LuaMathParser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Parser/Parser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:getExpression(luaParser, tokens, startIndex, errorOnFail)
  local errorOnFail = (errorOnFail == nil and true)
  local PatchedMathParser = MathParser:new(tokens, {
    unary = {
      ["-"] = 5,
    },
    binary = {
      ["^"] = 4,
      
      ["*"] = 3, ["/"] = 3, ["%"] = 3,
      ["+"] = 2, ["-"] = 2,
      
      ["<"] = 1, [">"] = 1, ["<="] = 1, 
      [">="] = 1, ["=="] = 1, ["~="] = 1,
      ["and"] = 1, ["or"] = 1
    }
  }, startIndex)

  function PatchedMathParser:syncLuaParser()
    luaParser.currentTokenIndex = self.currentTokenIndex -- ((self.unexpectedEnd and 1) or -1)
    luaParser.currentToken = luaParser.tokens[luaParser.currentTokenIndex]
  end
  function PatchedMathParser:syncMathParser()
    self.tokens = luaParser.tokens -- Just in case 
    self.currentTokenIndex = luaParser.currentTokenIndex
  end

  function PatchedMathParser:createOperatorNode(operatorValue, leftExpr, rightExpr, operand)
    return { TYPE = "Operator", Value = operatorValue, Left = leftExpr, Right = rightExpr, Operand = operand }
  end
  function PatchedMathParser:createFunctionCallNode(expression, arguments)
    return { TYPE = "FunctionCall", Expression = expression, Arguments = arguments }
  end
  function PatchedMathParser:createIndexNode(index, value)
    return { TYPE = "Index", Index = index, Value = value }
  end
  function PatchedMathParser:createTableNode(values)
    return { TYPE = "Table", Values = values }
  end

  function PatchedMathParser:isClosingParenthesis(token)
    return token.TYPE == "Character" and token.Value == ")"
  end

  function PatchedMathParser:parseBinaryOperator(minPrecedence)
    local currentToken = self:getCurrentToken()
    if not currentToken then
      return error("Unexpected end of the expression")
    end

    local left = self:parseUnaryOperator()
    if not left then return end
    while true do
      local token = self:getCurrentToken()
      if not token or self:isClosingParenthesis(token) then break end

      local precedence = self:getPrecedence(token)
      if precedence then
        if precedence <= minPrecedence then break end

        self:consumeToken()
        local right = self:parseBinaryOperator(precedence)
        left = self:createOperatorNode(token.Value, left, right)
      elseif not precedence then
        self:syncLuaParser()
        local newLeft = luaParser:handleSpecialOperators(token, left)
        self:syncMathParser()
        if not newLeft then self.unexpectedEnd = true; break end
        left = newLeft
      end
    end
    return left
  end;
  function PatchedMathParser:parseUnaryOperator()
    local token = self:getCurrentToken()
    if not token then
      return error("Unexpected end of the expression")
    end 

    local value = token.Value
    local TYPE = token.TYPE
    if TYPE == "Operator" then
      if self.operatorPrecedences.unary[value] then
        self:consumeToken()
        local operand = self:parseUnaryOperator()
        return self:createOperatorNode(token.Value, nil, nil, operand)
      end
    elseif TYPE == "Character" and (value == "(" or value == ")") then
      if value == "(" then
        self:consumeToken()
        local expression = self:parseExpression()
        local currentToken = self:getCurrentToken() 
        if not currentToken or not self:isClosingParenthesis(currentToken) then
          error("Mismatched parentheses")
        end
        self:consumeToken()
        return expression
      elseif value == ")" then
        error("Unexpected closing parenthesis")
      end
    elseif TYPE == "String" or TYPE == "Number" or TYPE == "Identifier" or TYPE == "Constant" then
      self:consumeToken()
      return token
    else
      self:syncLuaParser()
      local operand = luaParser:handleSpecialOperands(token)
      self:syncMathParser()
      if operand then return operand end
    end

    local errorMessage = "Unexpected token: " .. stringifyTable(token) 
    if not errorOnFail then
      self.unexpectedEnd = true;
      self.errorMessage = errorMessage
      return
    end
    return error(errorMessage)
  end;
  function PatchedMathParser:parse()
    local expression = self:parseExpression()
    self:syncLuaParser()

    luaParser.currentTokenIndex = self.currentTokenIndex - ((self.unexpectedEnd and 1) or 0)
    return expression
  end;

  local result = PatchedMathParser:parse()
  return result
end

return LuaMathParser