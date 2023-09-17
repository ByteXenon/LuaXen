--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/MathParser/Lexer/Lexer")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local find = Helpers.TableFind
local insert = table.insert

-- * Lexer (Tokenizer) * --
local Lexer = {}
function Lexer:new(expression, operators, charPos)
  local LexerInstance = {}

  LexerInstance.charStream = (type(expression) == "string" and StringToTable(expression)) or expression
  LexerInstance.curChar = LexerInstance.charStream[charPos or 1]
  LexerInstance.curCharPos = charPos or 1
  LexerInstance.operators = operators or {"+", "-", "*", "/", "^"}

  for i,v in pairs(ParserBuilder.__raw__) do
    LexerInstance[i] = v
  end

  function LexerInstance:consumeNumber()
    return self:consumeDigit()
  end

  function LexerInstance:consumeConstant()
    local Value = self.curChar;
    if self:isDigit() then
      Value = self:consumeNumber()
    end
    return { TYPE = "Constant", Value = Value }
  end

  function LexerInstance:consumeToken()
    local curChar = self.curChar
    
    if self:isWhitespace() then
    elseif curChar == ")" or curChar == "(" then
      return { TYPE = "Parentheses", Value = curChar }
    elseif find(self.operators, curChar) then
      return { TYPE = "Operator", Value = curChar }
    else
      return self:consumeConstant()
    end
  end
  
  function LexerInstance:consumeTokens()
    local tokens = {}
    while self.curChar do
      local newToken = self:consumeToken()
      if newToken then
        if (newToken == -1) then break end
        insert(tokens, newToken)
      end
      self:consume()
    end
    return tokens
  end

  function LexerInstance:run()
    return self:consumeTokens()
  end

  return LexerInstance
end

return Lexer