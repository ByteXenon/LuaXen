--[[
  Name: Minifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Minifier/Minifier")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

local function stringFormat(str, formatTb)
  str = str:gsub("{([\1-\124\126-\255]+)}", function(formatValue)
    local foundFormatValue = formatTb[formatValue]
    if foundFormatValue then return foundFormatValue end
    return "" -- formatValue
  end)
  return str
end

--* Minifier *--
local Minifier = {}
function Minifier:new(tokens)
  local MinifierInstance = {}
  MinifierInstance.tokens = tokens
  MinifierInstance.currentTokenIndex = 1
  MinifierInstance.currentToken = tokens[1]

  function MinifierInstance:peek(n)
    return self.tokens[self.currentTokenIndex + (n or 1)]
  end
  function MinifierInstance:consume(n)
    self.currentTokenIndex = self.currentTokenIndex + (n or 1)
    self.currentToken = self.tokens[self.currentTokenIndex]
    return self.currentToken
  end


  function MinifierInstance:isKeywordOrIdentifierOrNumber(token)
    local tokenType = token and token.TYPE
    return tokenType == "Identifier" or tokenType == "Keyword" or tokenType == "Number"
  end
  function MinifierInstance:isIdentifierOrNumber(token)
    local tokenType = token and token.TYPE
    return tokenType == "Identifier" or tokenType == "Number"
  end
  function MinifierInstance:isIdentifier(token)
    local tokenType = token and token.TYPE
    return tokenType == "Identifier"
  end
  function MinifierInstance:isKeyword(token)
    local tokenType = token and token.TYPE
    return tokenType == "Keyword"
  end
  function MinifierInstance:processCurrentToken()
    local token = self.currentToken
    local tokenValue = token.Value
    local tokenType = token.TYPE
    if tokenType == "Keyword" then
      tokenValue = ((self:isKeywordOrIdentifierOrNumber(self:peek(-1)) and " ") or "") .. tokenValue
    elseif tokenType == "Identifier" then
      tokenValue = ((self:isKeywordOrIdentifierOrNumber(self:peek(-1)) and " ") or "") .. tokenValue
    elseif tokenType == "Number" then
      tokenValue = ((self:isKeywordOrIdentifierOrNumber(self:peek(-1)) and " ") or "") .. tokenValue
    elseif tokenType == "String" then
      tokenValue = "'" .. tokenValue .. "'"
    end
    return tokenValue
  end
  function MinifierInstance:run()
    local strings = {}
    while self.currentToken do
      insert(strings, self:processCurrentToken())
      self:consume()
    end

    return concat(strings)
  end
  return MinifierInstance
end

return Minifier