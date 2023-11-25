--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Lexer/Lexer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local TokenFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/TokenFactory")

--* Export library functions *--
local insert = table.insert
local concat = table.concat
local byte = string.byte
local char = string.char
local rep = string.rep
local find = table.find or Helpers.TableFind
local stringToTable = Helpers.StringToTable

--* Local functions *--
local function makeTrie(table)
  local trieTable = {}
  local longestElement = 0

  for _, op in ipairs(table) do
    if #op > longestElement then
      longestElement = #op
    end

    local node = trieTable
    for index = 1, #op do
      local character = op:sub(index, index)
      node[character] = node[character] or {}
      node = node[character]
    end
    node.value = op
  end
  return trieTable, longestElement
end

--* Constants *--
local createEOFToken        = TokenFactory.createEOFToken
local createNewLineToken    = TokenFactory.createNewLineToken
local createWhitespaceToken = TokenFactory.createWhitespaceToken
local createCommentToken    = TokenFactory.createCommentToken
local createNumberToken     = TokenFactory.createNumberToken
local createConstantToken   = TokenFactory.createConstantToken
local createOperatorToken   = TokenFactory.createOperatorToken
local createKeywordToken    = TokenFactory.createKeywordToken
local createIdentifierToken = TokenFactory.createIdentifierToken
local createCharacterToken  = TokenFactory.createCharacterToken
local createStringToken     = TokenFactory.createStringToken

local escapedCharConversions = {
  ["a"]     = "\a", -- bell
  ["b"]     = "\b", -- backspace
  ["f"]     = "\f", -- form feed
  ["n"]     = "\n", -- newline
  ["r"]     = "\r", -- carriage return
  ["t"]     = "\t", -- horizontal tab
  ["v"]     = "\v", -- vertical tab
  ["z"]     = "\z", -- skips whitespace

  ["\\"]  = "\\", -- backslash
  ['"']   = '"',  -- double quote
  ["'"]   = "'",  -- single quote
}

local constants = {
  "false", "true", "nil", "..."
}
local reservedKeywords = {
  "while", "do", "end", "for",
  "local", "repeat", "until", "return",
  "in", "if", "else", "elseif",
  "function", "then", "break", "continue"
}
local operators = {
  "^", "*", "/", "%",
  "+", "-", "<", ">",
  "#",

  "<=", ">=", "==", "~=",
  "and", "or", "not", ".."
}

local constantTrie, longestConstant = makeTrie(constants)
local operatorTrie, longestOperator = makeTrie(operators)

--* LexerMethods *--
local LexerMethods = {}

function LexerMethods:peek(n)
  return ((self.charStream[self.curCharPos + (n or 1)]) or "\0")
end

function LexerMethods:consume(n)
  self.curCharPos = (self.curCharPos + (n or 1))
  self.curChar = ((self.charStream[self.curCharPos]) or "\0")
  return self.curChar
end

function LexerMethods:insertToken(token)
  token.Line = self.lineCounter
  return insert(self.tokens, token)
end

function LexerMethods:readWhileChar(char)
  local str = {}
  while self.curChar == char do
    insert(str, self.curChar)
    self:consume()
  end
  return concat(str)
end

function LexerMethods:isNumber()
  local char = self.curChar
  local nextChar = self:peek()

  return (char:match("%d"))
          or ((char == ".") and nextChar:match("%d") )
end

function LexerMethods:isIdentifier(char)
  local char = char or self.curChar
  return char:match("[%a_]")
end

function LexerMethods:isVarArg()
  local function checkChar(char) return char == "." end
  return checkChar(self.curChar) and checkChar(self:peek(1)) and checkChar(self:peek(2))
end

function LexerMethods:isWhitespace(char)
  local char = char or self.curChar
  return char:match("[\9\27\32]")
end

function LexerMethods:consumeWhitespace()
  local whitespace = {self.curChar}
  while self:isWhitespace(self:peek()) do
    insert(whitespace, self:consume())
  end
  return concat(whitespace)
end

function LexerMethods:consumeIdentifier()
  local identifier = {self.curChar}
  while self:peek():match("[%a%d_]") do
    insert(identifier, self:consume())
  end
  return concat(identifier)
end

function LexerMethods:isInteger()
  return self.curChar:match("%d")
end

function LexerMethods:consumeInteger(maxLength)
  local integer = {self.curChar}
  while self:peek():match("[%d]") do
    if #integer >= maxLength then break end
    insert(integer, self:consume())
  end
  return concat(integer)
end

function LexerMethods:consumeNumber()
  local number = {self.curChar}
  local isFloat = false
  local isScientific = false
  local isHex = false

  -- Check for hexadecimal numbers
  if self.curChar == '0' and (self:peek() == 'x' or self:peek() == 'X') then
    isHex = true
    insert(number, self:consume()) -- consume 'x' or 'X'
  end

  while self:peek():match((isHex and "[%da-fA-F]") or "[%d]") do
    insert(number, self:consume())
  end

  -- Check for floating point numbers
  if not isHex and self:peek() == "." then
    isFloat = true
    insert(number, self:consume()) -- consume '.'
    while self:peek():match("[%d]") do
      insert(number, self:consume())
    end
  end

  -- Check for scientific notation
  if not isHex and (self:peek() == "e" or self:peek() == "E") then
    isScientific = true
    insert(number, self:consume()) -- consume 'e' or 'E'
    if self:peek():match("[+-]") then
      insert(number, self:consume()) -- consume '+' or '-'
    end
    while self:peek():match("[%d]") do
      insert(number, self:consume())
    end
  end

  return concat(number)
end

function LexerMethods:expectChars(...)
  local expectedChars = {...}
  local curChar = self.curChar

  if find(expectedChars, curChar) then
    return self:consume()
  end
  error(("Error: Expected one of characters: {%s}, got: %s"):format(concat(expectedChars, ", "), curChar))
end

function LexerMethods:readWhileNotString(targetString, allowUnexpectedEnd)
  local stringTb = stringToTable(targetString)
  local stringLen = #targetString
  local matchedIndex = 1

  local returnString = {}
  while matchedIndex <= stringLen do
    local curChar = self.curChar
    if curChar == "\0" then
      if allowUnexpectedEnd then
        return concat(returnString):sub(0, -matchedIndex)
      end
      return error("Unexpected end")
    elseif stringTb[matchedIndex] == curChar then
      matchedIndex = matchedIndex + 1
      if matchedIndex > stringLen then
        break
      end
    else
      matchedIndex = 1
    end
    insert(returnString, curChar)
    self:consume()
  end

  return concat(returnString):sub(0, -matchedIndex)
end

function LexerMethods:isString()
  local curChar = self.curChar
  local nextChar = self:peek()

  return (curChar == "'" or curChar == '"') or
         (curChar == "[" and (nextChar == "[" or
         (nextChar == "=" and (self:peek() == "[" or self:peek() == "="))))
end

function LexerMethods:isComment()
  return self.curChar == "-" and self:peek() == "-"
end

function LexerMethods:consumeOperator()
  local node = operatorTrie
  local operator
  for i = 0, longestOperator - 1 do
    local character = self:peek(i)
    node = node[character]
    if not node then break end
    if node.value then operator = node.value end
  end
  if operator then self:consume(#operator - 1) end
  return operator
end

function LexerMethods:consumeConstant()
  local node = constantTrie
  local constant
  for i = 0, longestConstant - 1 do
    local character = self:peek(i)
    node = node[character]
    if not node then break end
    if node.value then constant = node.value end
  end
  if constant then self:consume(#constant - 1) end
  return constant
end

function LexerMethods:consumeSimpleString()
  local newString = {}
  local startQuote = self.curChar
  if self.includeHighlightTokens then insert(newString, self.curChar) end
  self:consume()

  while self.curChar ~= startQuote do
    local curChar = self.curChar
    if curChar == "\\" then
      local nextChar = self:consume()
      if self:isInteger() then
        local number = self:consumeInteger(3)
        insert(newString, char(tonumber(number)))
      elseif escapedCharConversions[nextChar] then
        insert(newString, escapedCharConversions[nextChar])
      else
        error("invalid escape sequence near '<placeholder>'")
      end
    else
      insert(newString, curChar)
    end
    self:consume()
  end
  if self.includeHighlightTokens then insert(newString, self.curChar) end

  return concat(newString)
end

function LexerMethods:consumeComplexString()
  self:expectChars("[")
  local depth = #self:readWhileChar("=")
  self:expectChars("[")

  local closingString = "]" .. rep("=", depth) .. "]"
  return self:readWhileNotString(closingString)
end

function LexerMethods:consumeComplexComment()
  self:expectChars("[")
  local depth = #self:readWhileChar("=")
  self:expectChars("[")

  while self.curChar ~= "\0" do
    local curChar = self.curChar
    if curChar == "\0" then
      return error("Unexpected end")
    elseif curChar == "]" then
      self:consume()
      local depthCounter = 0
      while self.curChar:match("=") do
        depthCounter = depthCounter + 1
        self:consume()
      end
      if self.curChar == "]" and depthCounter == depth then
        break
      end
    elseif curChar == "\n" then
      self.lineCounter = self.lineCounter + 1
    end
    self:consume()
  end

end

function LexerMethods:consumeString()
  local nextChar = self:peek()
  if self.curChar == "'" or self.curChar == '"' then
    return self:consumeSimpleString()
  elseif self.curChar == "[" and (nextChar == "=" or nextChar == "[") then
    return self:consumeComplexString()
  end
end

function LexerMethods:consumeComment()
  self:expectChars("-")
  self:expectChars("-")

  local curChar = self.curChar
  local nextChar = self:peek()
  if curChar == '[' and (nextChar == '[' or nextChar == "=") then
    return self:consumeComplexComment()
  else
    self:readWhileNotString("\n", true)
    return self:consume(-1)
  end
end

function LexerMethods:tokenizeNextToken()
  local curChar = self.curChar
  if curChar == "\n" then
    self.lineCounter = self.lineCounter + 1
    if self.includeHighlightTokens then
      return self:insertToken(createNewLineToken())
    end
    return
  elseif self:isWhitespace() then
    local whitespace = self:consumeWhitespace()
    if self.includeHighlightTokens then
      return self:insertToken(createWhitespaceToken(whitespace))
    end
    return
  elseif self:isComment() then
    insert(self.comments, {
      Position = #self.tokens,
      Value = self:consumeComment()
    })
    if self.includeHighlightTokens then
      return self:insertToken(createCommentToken(self:consumeComment()))
    end
    return
  elseif self:isNumber() then
    local newNumber = self:consumeNumber()
    return self:insertToken(createNumberToken(tonumber(newNumber)))
  elseif self:isIdentifier() then
    local newIdentifier = self:consumeIdentifier()
    if find(constants, newIdentifier) then
      local constantValue
      if newIdentifier ~= "nil" then
        constantValue = newIdentifier == "true"
      end

      return self:insertToken(createConstantToken(constantValue))
    elseif find(operators, newIdentifier) then
      return self:insertToken(createOperatorToken(newIdentifier))
    elseif find(reservedKeywords, newIdentifier) then
      return self:insertToken(createKeywordToken(newIdentifier))
    else
      return self:insertToken(createIdentifierToken(newIdentifier))
    end
  elseif self:isString() then
    local newString = self:consumeString()
    return self:insertToken(createStringToken(newString))
  elseif self:isVarArg() then
    self:consume(1) -- Consume "."
    self:consume(1) -- Consume "."
    -- Due to the pattern we're following here,
    -- leave the last "." without consuming it.

    -- it would be easier to treat varargs as identifiers during
    -- execution/instruction gen phase
    return self:insertToken(createIdentifierToken("..."))
  end

  local operator = self:consumeOperator()
  if operator then
    return self:insertToken(createOperatorToken(operator))
  end

  return self:insertToken(createCharacterToken(curChar))
end

-- Main (public)
function LexerMethods:tokenize()
  while self.curChar ~= "\0" do
    self:tokenizeNextToken()
    self:consume()
  end

  return self.tokens
end

--* Lexer *--
local Lexer = {}
function Lexer:new(string, includeHighlightTokens)
  local LexerInstance = {}
  LexerInstance.includeHighlightTokens = includeHighlightTokens
  LexerInstance.charStream = stringToTable(string)
  LexerInstance.curCharPos = 1
  LexerInstance.lineCounter = 1
  LexerInstance.curChar = LexerInstance.charStream[1] or "\0"
  LexerInstance.tokens = {}
  LexerInstance.comments = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if LexerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and LexerInstance: " .. index)
      end
      LexerInstance[index] = value
    end
  end

  -- Main
  inheritModule("LexerMethods", LexerMethods)

  return LexerInstance
end

return Lexer