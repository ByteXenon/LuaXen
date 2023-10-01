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
local Debugger = ModuleManager:loadModule("Debugger/Debugger")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:getExpression(luaParser, tokens, startIndex, errorOnFail)
  local errorOnFail = false

  local PatchedMathParser = MathParser:new(tokens, {
    unary = {
      ["-"] = 8, ["#"] = 8, ["not"] = 8
    },
    binary = {
      ["^"] = 7,
      ["*"] = 6, ["/"] = 6, ["%"] = 6,
      ["+"] = 5, ["-"] = 5,
      [".."] = 4,
      ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["=="] = 3, ["~="] = 3,
      ["and"] = 2,
      ["or"] = 1
    }
  }, startIndex)

  function PatchedMathParser:getCurrentToken()
    return self.tokens[self.currentTokenIndex] or { TYPE = "EOF" }
  end;
  function PatchedMathParser:peek()
    return self.tokens[self.currentTokenIndex + 1] or { TYPE = "EOF" }
  end;
  function PatchedMathParser:consumeToken()
    self.currentTokenIndex = self.currentTokenIndex + 1
  end;

  function PatchedMathParser:syncLuaParser()
    luaParser.currentTokenIndex = self.currentTokenIndex -- ((self.unexpectedEnd and 1) or -1)
    luaParser.currentToken = luaParser.tokens[luaParser.currentTokenIndex] or { TYPE = "EOF" }
  end
  function PatchedMathParser:syncMathParser()
    self.tokens = luaParser.tokens -- Just in case 
    self.currentTokenIndex = luaParser.currentTokenIndex
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
    if not left then
      self.unexpectedEnd = true;
      return currentToken
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
        self:consumeToken()
        local right = self:parseBinaryOperator(precedence)
        left = luaParser:createOperatorNode(token.Value, left, right, precedence)
      elseif not precedence then
        
        self:syncLuaParser()
        local newLeft = luaParser:handleSpecialOperators(token, left)
        self:syncMathParser()
        if not newLeft then self.unexpectedEnd = true; return left end

        self:consumeToken() -- Consume the last character of an operator
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
        return luaParser:createUnaryOperatorNode(token.Value, operand, precedence)
      end
    elseif TYPE == "Character" and (value == "(" or value == ")") then
      if value == "(" then
        self:consumeToken()
        self.isInParentheses = true
        local expression = self:parseExpression()
        local currentToken = self:getCurrentToken()
        if not currentToken or not self:isClosingParenthesis(currentToken) then
          error("Mismatched parentheses")
        end
        self.isInParentheses = false
        self:consumeToken()
        return expression
      elseif value == ")" then
        if not errorOnFail then
          self.unexpectedEnd = true;
          self.errorMessage = errorMessage
          return
        end

        error("Unexpected closing parenthesis")
      end
    elseif TYPE == "String" or TYPE == "Number" or TYPE == "Identifier" or TYPE == "Constant" then
      self:consumeToken()
      return token
    else
      self:syncLuaParser()
      local operand = luaParser:handleSpecialOperands(token)
      self:syncMathParser()
      self:consumeToken() -- Consume the last character of an operand
      

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
    luaParser.currentTokenIndex = self.currentTokenIndex - ((self.unexpectedEnd and 1) or 0)
    luaParser.currentToken = luaParser.tokens[luaParser.currentTokenIndex]
    
    return expression
  end;

  local result = PatchedMathParser:parse()
  return result
end

return LuaMathParser