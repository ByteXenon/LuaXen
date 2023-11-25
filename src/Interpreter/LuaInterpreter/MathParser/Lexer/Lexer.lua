--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/MathParser/Lexer/Lexer")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local TokenFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Lexer/TokenFactory")

--* Export library functions *--
local stringToTable = Helpers.StringToTable
local find = Helpers.TableFind
local concat = table.concat
local insert = table.insert

local createConstantToken = TokenFactory.createConstantToken
local createParenthesesToken = TokenFactory.createParenthesesToken
local createOperatorToken = TokenFactory.createOperatorToken

-- * Lexer (Tokenizer) * --
local Lexer = {}
function Lexer:new(expression, operators, charPos)
  local LexerInstance = {}

  LexerInstance.charStream = (type(expression) == "string" and stringToTable(expression)) or expression
  LexerInstance.curChar = LexerInstance.charStream[charPos or 1]
  LexerInstance.curCharPos = charPos or 1
  LexerInstance.operators = (operators or {"+", "-", "*", "/", "^"})

  function LexerInstance:peek(n)
    return self.charStream[self.curCharPos + (n or 1)]
  end
  function LexerInstance:consume(n)
    self.curCharPos = self.curCharPos + (n or 1)
    self.curChar = self.charStream[self.curCharPos]
    return self.curChar
  end

  function LexerInstance:isDigit(char)
    return (char or self.curChar):match("%d")
  end
  function LexerInstance:isWhitespace(char)
    return (char or self.curChar):match("%s")
  end

  function LexerInstance:consumeNumber()
    local number = {}
    repeat
      insert(number, self.curChar)
    until not (self:peek():match("%d") and self:consume())
    return concat(number)
  end

  function LexerInstance:consumeConstant()
    local value = self.curChar;
    if self:isDigit() then
      value = self:consumeNumber()
    end
    return createConstantToken(value)
  end

  function LexerInstance:consumeToken()
    local curChar = self.curChar

    if self:isWhitespace() then
    elseif curChar == ")" or curChar == "(" then
      return createParenthesesToken(curChar)
    elseif find(self.operators, curChar) then
      return createOperatorToken(curChar)
    else
      return self:consumeConstant()
    end
  end

  function LexerInstance:consumeTokens()
    local tokens = {}
    while self.curChar do
      local newToken = self:consumeToken()
      insert(tokens, newToken)
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