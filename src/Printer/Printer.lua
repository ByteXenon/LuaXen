--[[
  Name: Printer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Printer/Printer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* Printer *--
local Printer = {}
function Printer:new(astHierarchy)
  local PrinterInstance = {}
  PrinterInstance.ast = astHierarchy

  function PrinterInstance:peek(n)
    return self.tokens[self.currentTokenIndex + (n or 1)]
  end
  function PrinterInstance:consume(n)
    self.currentTokenIndex = self.currentTokenIndex + (n or 1)
    self.currentToken = self.tokens[self.currentTokenIndex]
    return self.currentToken
  end

  function PrinterInstance:isKeywordOrIdentifierOrNumber(token)
    return self:isIdentifierOrNumber(token) or self:isKeyword(token)
  end

  function PrinterInstance:isIdentifierOrNumber(token)
    return self:isIdentifier(token) or (token and token.TYPE == "Number")
  end

  function PrinterInstance:isIdentifier(token)
    local tokenType = token and token.TYPE
    local tokenValue = token and token.Value
    local identifierOperators = {"and", "or", "not"}

    return tokenType == "Identifier" or (tokenType == "Constant" and tokenValue ~= "...") or
          ((tokenType == "Operator" or tokenType == "UnaryOperator") and find(identifierOperators, tokenValue))
  end

  function PrinterInstance:isKeyword(token)
    return token and token.TYPE == "Keyword"
  end

  function PrinterInstance:processCurrentToken(tokens, tokenIndex)
    local token = tokens[tokenIndex]
    local tokenValue = token.Value
    local tokenType = token.TYPE

    if self:isKeywordOrIdentifierOrNumber(token) then
      tokenValue = ((self:isKeywordOrIdentifierOrNumber(tokens[tokenIndex - 1]) and " ") or "") .. tokenValue
    elseif tokenType == "String" then
      tokenValue = "'" .. tokenValue .. "'"
    end

    return tokenValue
  end
  function PrinterInstance:processTokens(tokens)
    local strings = {}

    local tokenIndex = 1
    while tokens[tokenIndex] do
      insert(strings, self:processCurrentToken(tokens, tokenIndex))
      tokenIndex = tokenIndex + 1
    end

    return concat(strings)
  end
  function PrinterInstance:run()
    local tokens = self.ast:getTokens()
    return self:processTokens(tokens)
  end

  return PrinterInstance
end

return Printer