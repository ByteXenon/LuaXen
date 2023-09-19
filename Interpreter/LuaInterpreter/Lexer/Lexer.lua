--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Lexer/Lexer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local insert = table.insert
local byte = string.byte
local concat = table.concat
local char = string.char
local find = table.find or Helpers.TableFind
local rep = string.rep

local function makeTrie(tb)
  local trieTb = {}
  local longestElement = 0

  for _, op in ipairs(tb) do
    if #op > longestElement then
      longestElement = #op
    end

    local node = trieTb
    for i = 1, #op do
      local c = op:sub(i, i)
      node[c] = node[c] or {}
      node = node[c]
    end
    node.value = op
  end
  return trieTb, longestElement
end

--* Lexer *--
local Lexer = {}
function Lexer:new(string)
  local LexerInstance = {}
  LexerInstance.charStream = StringToTable(string)
  LexerInstance.curCharPos = 1
  LexerInstance.curChar = LexerInstance.charStream[1]
  LexerInstance.reservedKeywords = {
    "while", "do", "end", "for", 
    "local", "repeat", "until", "return", 
    "in", "if", "else", "elseif", 
    "function", "then", "break", "continue"
  }
  LexerInstance.constants = {
    "false", "true", "nil", "..."
  }
  LexerInstance.operators = {
    "^", "*", "/", "%", 
    "+", "-", "<", ">", 
    "#",
    
    "<=", ">=", "==", "~=",
    "and", "or", "not", ".."
  }

  LexerInstance.constantTrie, LexerInstance.longestConstant = makeTrie(LexerInstance.constants)
  LexerInstance.operatorTrie, LexerInstance.longestOperator = makeTrie(LexerInstance.operators)

  function LexerInstance:peek(n)
    return self.charStream[self.curCharPos + (n or 1)] or "\0"
  end;
  function LexerInstance:consume(n)
    self.curCharPos = self.curCharPos + (n or 1)
    self.curChar = self.charStream[self.curCharPos] or "\0"
    return self.curChar
  end;
  function LexerInstance:readWhileChar(char)
    local str = {}
    while self.curChar == char do
      insert(str, self.curChar)
      self:consume()
    end
    return concat(str);
  end;

  function LexerInstance:isDigit(char)
    local char = char or self.curChar
    return char:match("%d")
  end
  function LexerInstance:isIdentifier(char)
    local char = char or self.curChar
    return char:match("[%a_]")
  end
  function LexerInstance:isWhitespace(char)
    local char = char or self.curChar
    return char:match("%s")
  end;
  function LexerInstance:consumeWhitespace()
    while self:isWhitespace(self:peek()) do
      self:consume()
    end
  end;
  function LexerInstance:consumeIdentifier()
    local identifier = {self.curChar}
    while self:peek():match("[%a%d_]") do
      insert(identifier, self:consume())
    end
    return concat(identifier)
  end
  function LexerInstance:consumeDigit()
    local digit = {self.curChar}
    while self:peek():match("[%d]") do
      insert(digit, self:consume())
    end
    return concat(digit)
  end
  function LexerInstance:expectChars(...)
    local expectedChars = {...}
    local curChar = self.curChar

    if find(expectedChars, curChar) then
      self:consume()
      return curChar
    end
    error(("Error: Expected one of characters: {%s}, got: %s"):format(concat(expectedChars, ", "), curChar))
  end;
  function LexerInstance:readWhileNotString(targetString)
    local stringTb = StringToTable(targetString)
    local stringLen = #targetString
    local matchedIndex = 1;
    
    local returnString = {}
    while matchedIndex <= stringLen do
      local curChar = self.curChar
      if curChar == "\0" then
        return error("Unexpected end")
      elseif stringTb[matchedIndex] == curChar then
        matchedIndex = matchedIndex + 1
      else
        matchedIndex = 1
      end
      insert(returnString, curChar)
      self:consume()
    end

    return concat(returnString):sub(0, -matchedIndex)
  end;
  function LexerInstance:isString()
    local curChar = self.curChar;
    local nextChar = self:peek()

    return (curChar == "'" or curChar == '"') or
           (curChar == "[" and (nextChar == "[" or
           (nextChar == "=" and (self:peek() == "[" or self:peek() == "="))))
  end;
  function LexerInstance:isComment()
    return self.curChar == "-" and self:peek() == "-"
  end;

  function LexerInstance:consumeOperator()
    local node = self.operatorTrie
    local operator;
    for i = 0, self.longestOperator - 1 do
        local character = self:peek(i)
        node = node[character]
        if not node then break end
        if node.value then operator = node.value end
    end
    if operator then self:consume(#operator - 1) end
    return operator
  end
  function LexerInstance:consumeConstant()
    local node = self.constantTrie
    local constant;
    for i = 0, self.longestConstant - 1 do
        local character = self:peek(i)
        node = node[character]
        if not node then break end
        if node.value then constant = node.value end
    end
    if constant then self:consume(#constant - 1) end
    return constant
  end

  function LexerInstance:consumeSimpleString()
    local startQuote = self.curChar
    self:consume()

    local newString = {};
    while self.curChar ~= startQuote do
      local curChar = self.curChar
      if curChar == "\\" then
        local nextChar = self:consume()
        if self:isDigit() then
          insert(newString, char(tonumber(self:consumeDigit())))
        else
          insert(newString, nextChar)
        end
      else
        insert(newString, curChar)
      end
      self:consume()
    end

    return concat(newString)
  end
  function LexerInstance:consumeComplexString()
    self:expectChars("[")
    local depth = #self:readWhileChar("=")
    self:expectChars("[")
    
    local closingString = "]" .. rep("=", depth) .. "]"
    return self:readWhileNotString(closingString)
  end
  function LexerInstance:consumeString()
    local nextChar = self:peek();
    if self.curChar == "'" or self.curChar == '"' then
      return self:consumeSimpleString()
    elseif self.curChar == "[" and (nextChar == "=" or nextChar == "[") then
      return self:consumeComplexString()
    end;
  end;
  function LexerInstance:consumeComment()
    self:expectChars("-")
    self:expectChars("-")

    local curChar = self.curChar;
    local nextChar = self:peek()
    if curChar == '[' and (nextChar == '[' or nextChar == "=") then
      return self:consumeString()
    else
      return self:readWhileNotString("\n")
    end;
  end;

  function LexerInstance:newToken(tokenType, tokenValue)
    return { TYPE = tokenType, Value = tokenValue }
  end
  function LexerInstance:getNextToken()
    local curChar = self.curChar
    if self:isWhitespace() then
      self:consumeWhitespace()
      return
    elseif self:isComment() then
      self:consumeComment()
      return
    elseif self:isDigit() then
      local newNumber = self:consumeDigit() 
      return self:newToken("Number", tonumber(newNumber))
    elseif self:isIdentifier() then
      local newIdentifier = self:consumeIdentifier()
      if find(self.constants, newIdentifier) then
        local constantValue;
        if newIdentifier == "nil" then
        else
          constantValue = newIdentifier == "true"
        end
        return self:newToken("Constant", constantValue)
      elseif find(self.operators, newIdentifier) then
        return self:newToken("Operator", newIdentifier)
      elseif find(self.reservedKeywords, newIdentifier) then
        return self:newToken("Keyword", newIdentifier)
      end
      return self:newToken("Identifier", newIdentifier)
    elseif self:isString() then
      local newString = self:consumeString()
      return self:newToken("String", newString)
    end

    -- Check if this is a constant or an operator
    local constant = self:consumeConstant()
    if constant then return self:newToken("Constant", constant) end
    local operator = self:consumeOperator()
    if operator then return self:newToken("Operator", operator) end

    return self:newToken("Character", curChar)
  end

  function LexerInstance:tokenize()
    local tokens = {}
    while self.curChar ~= "\0" do
      local nextToken = self:getNextToken()
      if nextToken then insert(tokens, nextToken) end
      self:consume()
    end
    insert(tokens, self:newToken("EOF"))

    return tokens
  end;

  return LexerInstance
end

return Lexer