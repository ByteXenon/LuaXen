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
function LuaMathParser:getExpression(luaParser, tokens, startIndex)
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
    luaParser.currentTokenIndex = self.currentTokenIndex - ((self.unexpectedEnd and 1) or 0)
    luaParser.currentToken = luaParser.tokens[luaParser.currentTokenIndex]
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
        local newLeft = self:handleSpecialCharacters(token, left)
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
    elseif TYPE == "Character" then
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
    end

    return error("Unexpected token: " .. stringifyTable(token))
  end;
  function PatchedMathParser:parse()
    local expression = self:parseExpression()
    self:syncLuaParser()

    return expression
  end;

  local result = PatchedMathParser:parse()
  return result
end

return LuaMathParser