--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Parser/Parser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local find = Helpers.TableFind
local insert = table.insert
local concat = table.concat

-- * Parser * --
local Parser = {};
function Parser:new(tokens, luaState)
  local StatementParser = ModuleManager:loadModule("Assembler/Parser/StatementParser")

  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.tokenPos = 1
  ParserInstance.curToken = tokens[1]
  ParserInstance.luaState = luaState or LuaState:new()
  ParserInstance.labels = {}

  for index, value in pairs(StatementParser) do
    ParserInstance[index] = value
  end

  function ParserInstance:peek(n)
    return self.tokens[self.tokenPos + (n or 1)]
  end
  function ParserInstance:consume(n)
    self.tokenPos = self.tokenPos + (n or 1)
    self.curToken = self.tokens[self.tokenPos]
    return self.curToken
  end

  function ParserInstance:findOrCreateConstant(value)
    local constants = self.luaState.constants
    local constantIndex = find(constants, value)
    if not constantIndex then
      insert(constants, value)
      constantIndex = #constants
    end
    return -constantIndex
  end

  function ParserInstance:compareToken(token, type, value)
    if (token and token.Type == type and (not value or token.Value == value)) then
      return true
    end
    return false
  end
  function ParserInstance:expectCurToken(type, value, dontConsume)
    local curToken = self.curToken
    if not curToken or not (curToken.Type == type and curToken.Value == value) then
      error("[]")
    end
    if not dontConsume then self:consume() end
    return curToken
  end
  function ParserInstance:parseToken()
    if self:compareToken(self.curToken, "Identifier") then
      return self:identifier()
    end
    print(self.curToken.Type, self.curToken.Value)
    return error(2)
  end
  function ParserInstance:parseTokens(stopTokens)
    while self.curToken do
      if stopTokens then
        local curToken = self.curToken
        for _, stopToken in ipairs(stopTokens) do
          local curTokenType, stopTokenValue = curToken.Type, stopToken.Type
          local curTokenValue, stopTokenValue = curToken.Value, stopToken.Value
          if curTokenType == stopTokenType and curTokenValue == stopTokenValue then
            return ast
          end
        end
      end
      self:parseToken()
      self:consume()
    end
  end
  function ParserInstance:parse()
    self:parseTokens()
    return self.luaState
  end

  return ParserInstance
end

return Parser