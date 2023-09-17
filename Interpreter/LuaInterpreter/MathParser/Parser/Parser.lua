--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/MathParser/Parser/Parser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local Class = Helpers.NewClass

local Parser = {}
function Parser:new(tokens, operatorPrecedences, tokenindex, errorOnFail)
  local ParserInstance = {}
 
  ParserInstance.currentTokenIndex = tokenindex or 1
  ParserInstance.tokens = tokens
  ParserInstance.errorOnFail = errorOnFail == nil
  ParserInstance.operatorPrecedences = operatorPrecedences or {
    unary = {
      -- Unary minus precedence
      ["-"] = 4,
    },
    binary = {
      ["^"] = 3,
      ["*"] = 2,
      ["/"] = 2,
      ["%"] = 2,
      ["+"] = 1,
      ["-"] = 1,
    }
  }
  
  function ParserInstance:getCurrentToken()
    return self.tokens[self.currentTokenIndex]
  end;
  function ParserInstance:peek()
    return self.tokens[self.currentTokenIndex + 1]
  end;
  function ParserInstance:consumeToken()
    self.currentTokenIndex = self.currentTokenIndex + 1
  end;
  
  function ParserInstance:parse()
    local expression = self:parseExpression()

    local remainingToken = self:getCurrentToken()
    if remainingToken and self.errorOnFail then
      error("Invalid expression: unexpected token '" .. remainingToken.Value .. "'")
    end

    return expression
  end;

  function ParserInstance:getPrecedence(token)
    return self.operatorPrecedences.binary[token and token.Value]
  end

  function ParserInstance:parseExpression()
    local expression = self:parseBinaryOperator(0)
    return expression
  end;

  function ParserInstance:parseBinaryOperator(minPrecedence)
    local currentToken = self:getCurrentToken()
    if not currentToken then error("Unexpected end") end
    if currentToken.TYPE == "Operator" and not self.operatorPrecedences.unary[currentToken.Value] then
      error("Invalid expression")
    end

    local left = self:parseUnaryOperator()
    while true do
      local token = self:getCurrentToken()
      if not token or token.Value == ")" then break end

      local precedence = self:getPrecedence(token)
      if precedence <= minPrecedence then
        break
      end
  
      self:consumeToken()
      local right = self:parseBinaryOperator(precedence)
      left = { TYPE = "Operator", Value = token.Value, Left = left, Right = right }
    end
    return left
  end;

  function ParserInstance:parseUnaryOperator()
    local token = self:getCurrentToken()
    if not token then
      if self.errorOnFail then
        error("Invalid expression")
      end
      -- You're on your own, goodluck
    end 

    local value = token.Value
    local TYPE = token.TYPE
    if TYPE == "Operator" then
      if self.operatorPrecedences.unary[value] then
        self:consumeToken()
        local operand = self:parseUnaryOperator()
        return { TYPE = "Operator", Value = value, Operand = operand }  
      end
    elseif TYPE == "Parentheses" then
      if value == "(" then
        self:consumeToken()
        local expression = self:parseExpression()
        if not self:getCurrentToken() or self:getCurrentToken().Value ~= ")" then
          error("Mismatched parentheses")
        end
        self:consumeToken()
        return expression
      elseif value == ")" then
        error("Unexpected closing parenthesis")
      end
    elseif TYPE == "Constant" then
      self:consumeToken()
      return token
    end

    error("Invalid expression")
  end;

  return ParserInstance
end

return Parser