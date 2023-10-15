--[[
  Name: LuaMathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/LuaMathParser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Parser/Parser")
local Debugger = ModuleManager:loadModule("Debugger/Debugger")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind

--* LuaMathParser *--
local LuaMathParser = {}
function LuaMathParser:getExpression(luaParser, tokens, startIndex, errorOnFail)
  local errorOnFail = false
  
  -- TODO
  local rightAssociativeOperators = { "^", ".." }
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
  function PatchedMathParser:isOperand(token)
    local tokenType = token.TYPE
    local operandTypes = {"String", "Number", "Identifier", "Constant"}
    return find(operandTypes, tokenType)
  end
  function PatchedMathParser:isRightAssociative(operator)
    return find(rightAssociativeOperators, operator)
  end  

  function PatchedMathParser:handleOperatorWithPrecedence(token, precedence, left, minPrecedence)
    local nextPrecedence = (self:isRightAssociative(token.Value) and precedence - 1) or precedence
    
    self:consumeToken()
    local right = self:parseBinaryOperator(nextPrecedence)
    if not right then return end
    return luaParser:createOperatorNode(token.Value, left, right, precedence)
  end

  function PatchedMathParser:handleSpecialOperators(token, leftExpr)
    self:syncLuaParser()
    local newLeft = luaParser:handleSpecialOperators(token, leftExpr)
    self:syncMathParser()
    return newLeft
  end

  function PatchedMathParser:parseBinaryOperator(minPrecedence)
    local currentToken = self:getCurrentToken()
    if not currentToken then
      return error("Unexpected end of the expression")
    end

    local left = self:parseUnaryOperator()
    if not left then
      --[[@PRIVATE
        Honestly, I don't care about the code quality anymore,
        I just want to go cry in a corner because...
        fucking hell.
        fuck it all.
      --]]
      self.unexpectedEnd = true;
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
        local newLeft = self:handleOperatorWithPrecedence(token, precedence, left, minPrecedence) 
        if not newLeft then
          self.unexpectedEnd = true;
          return
        end
        left = newLeft
      elseif not precedence then
        local newLeft = self:handleSpecialOperators(token, left);
        if not newLeft then
          self.unexpectedEnd = true;
          return left
        end

        left = newLeft
        self:consumeToken() -- Consume the last character of an operator
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
          return
        end

        error("Unexpected closing parenthesis")
      end
    elseif self:isOperand(token) then
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
    
    if expression then
      return luaParser:createExpressionNode(expression)
    end
    return expression
  end;

  local result = PatchedMathParser:parse()
  return result
end

return LuaMathParser