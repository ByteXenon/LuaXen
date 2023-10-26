--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Lexer/Lexer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local stringToTable = Helpers.StringToTable
local insert = table.insert
local concat = table.concat

-- * Lexer * --
local Lexer = {};
function Lexer:new(assemblyCode)
  local LexerInstance = {}
  LexerInstance.charStream = stringToTable(assemblyCode)
  LexerInstance.charPos = 1
  LexerInstance.curChar = LexerInstance.charStream[1]

  function LexerInstance:peek(n)
    return self.charStream[self.charPos + (n or 1)] or "\0"
  end
  function LexerInstance:consume(n)
    self.charPos = self.charPos + (n or 1)
    self.curChar = self.charStream[self.charPos] or "\0"
    return self.curChar
  end

  function LexerInstance:isIdentifier()
    return self.curChar:match("[%a_]")
  end
  function LexerInstance:consumeIdentifier()
    local identifier = {}
    repeat
      insert(identifier, self.curChar)
    until not (self:peek() and self:peek():match("[%a_]") and self:consume())
    return concat(identifier)
  end

  function LexerInstance:isString()
    return self.curChar == "'" or self.curChar == "\""
  end
  function LexerInstance:consumeString()
    local openingQuote = self.curChar
    self:consume()
    local newString = {}
    while (self.curChar ~= "\0" and self.curChar ~= openingQuote) do
      insert(newString, self.curChar)
      self:consume()
    end
    -- TODO: Add a special case for unfinished strings with '\0' at the end
    return concat(newString)
  end

  function LexerInstance:isNumber()
    if self.curChar == "-" then
      return self:peek():match("[%d]")
    end
    return self.curChar:match("[%d]")
  end
  function LexerInstance:consumeNumber()
    local number = {}
    repeat
      insert(number, self.curChar)
    until not (self:peek():match("%d"))
    return concat(number)
  end

  function LexerInstance:isComment()
    return self.curChar == ";"
  end
  function LexerInstance:consumeComment()
    local comment = {}
    while self:peek() ~= "\n" do
      insert(comment, self:consume())
    end
    return concat(comment)
  end

  function LexerInstance:isWhitespace()
    return self.curChar:match("%s")
  end
  function LexerInstance:consumeWhitespace()
    while self:peek():match("%s") do
      self:consume()
    end
  end

  function LexerInstance:newToken(tokenType, tokenValue)
    return { Type = tokenType, Value = tokenValue }
  end
  function LexerInstance:getCurrentToken()
    if self:isWhitespace() then
      self:consumeWhitespace()
      return
    elseif self:isIdentifier() then
      local newIdentifier = self:consumeIdentifier()
      return self:newToken("Identifier", newIdentifier)
    elseif self:isString() then
      local newString = self:consumeString()
      return self:newToken("String", newString)
    elseif self:isNumber() then
      local newNumber = self:consumeNumber()
      return self:newToken("Number", newNumber)
    elseif self:isComment() then
      self:consumeComment()
      return
    else
      return self:newToken("Character", self.curChar)
    end
  end
  function LexerInstance:tokenize()
    local tokens = {}
    while self.curChar ~= "\0" do
      local currentToken = self:getCurrentToken()
      if currentToken then
        insert(tokens, currentToken)
      end

      self:consume()
    end
    return tokens
  end

  return LexerInstance
end

return Lexer