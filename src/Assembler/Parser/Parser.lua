--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is a core component of a pseudo-assembly language parser.
    It takes a sequence of assembly tokens and parses them into a LuaState.
    The module handles various assembly statements and constructs, 
    effectively translating assembly code into a format that can be executed within a Lua environment.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Parser/Parser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")
local StatementParser = ModuleManager:loadModule("Assembler/Parser/StatementParser")

--* Export library functions *--
local find = Helpers.TableFind
local insert = table.insert
local concat = table.concat

--* ParserMethods *--
local ParserMethods = {}

function ParserMethods:peek(n)
  return self.tokens[self.tokenPos + (n or 1)]
end

function ParserMethods:consume(n)
  self.tokenPos = self.tokenPos + (n or 1)
  self.curToken = self.tokens[self.tokenPos]
  return self.curToken
end

function ParserMethods:findOrCreateConstant(value)
  local constants = self.luaState.constants
  local constantIndex = find(constants, value)
  if not constantIndex then
    insert(constants, value)
    constantIndex = #constants
  end
  return -constantIndex
end

function ParserMethods:compareToken(token, type, value)
  if (token and token.TYPE == type and (not value or token.Value == value)) then
    return true
  end
  return false
end

function ParserMethods:expectCurToken(type, value, dontConsume)
  local curToken = self.curToken
  if not curToken or not (curToken.TYPE == type and curToken.Value == value) then
    error("Expected token type: " .. type .. " (" .. value .. ")")
  end
  if not dontConsume then self:consume() end
  return curToken
end

function ParserMethods:parseToken()
  if self:compareToken(self.curToken, "Identifier") then
    return self:identifier()
  elseif self:compareToken(self.curToken, "String") then
    return self:findOrCreateConstant(self.curToken.Value)
  elseif self:compareToken(self.curToken, "Number") then
    return self:findOrCreateConstant(tonumber(self.curToken.Value))
  end
  return error("Unexpected token type: " .. tostring(self.curToken.TYPE) .. " (" .. self.curToken.Value .. ")")
end

function ParserMethods:parseTokens(stopTokens)
  while self.curToken do
    if stopTokens then
      local curToken = self.curToken
      for _, stopToken in ipairs(stopTokens) do
        local curTokenType, stopTokenValue = curToken.TYPE, stopToken.TYPE
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

function ParserMethods:parse()
  self:parseTokens()
  return self.luaState
end

--* Parser *--
local Parser = {};
function Parser:new(tokens, luaState)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.tokenPos = 1
  ParserInstance.curToken = tokens[1]
  ParserInstance.luaState = {}
  ParserInstance.labels = {}

  local function inheritModule(moduleName, moduleTable, field)
    for index, value in pairs(moduleTable) do
      if ParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ParserInstance: " .. index)
      end
      if field then
        ParserInstance[field][index] = value
      else
        ParserInstance[index] = value
      end
    end
  end

  -- Main
  inheritModule("ParserMethods", ParserMethods)
  inheritModule("StatementParser", StatementParser)

  -- LuaState
  inheritModule("LuaState", LuaState:new(), "luaState")

  return ParserInstance
end

return Parser