--[[
  Name: StatementParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is a part of a pseudo-assembly language parser,
    specifically responsible for parsing individual assembly statements.
    It handles identifiers, labels, and instructions, and also manages the parsing
    of different types of labels (function, string, and number labels).
    It also provides utility functions for instruction parameters handling and token manipulation.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Parser/StatementParser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
-- Don't load the Parser module here, as it would cause a circular dependency
local Parser = nil and ModuleManager:loadModule("Assembler/Parser/Parser")

--* Export library functions *--
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* Local functions *--
local function copyTable(table1)
  local table2 = {}
  for index, value in pairs(table1) do
    table2[index] = value
  end
  return table2
end

--[[
  <Identifier> {
   |    ':' : label() {
   |     |    '{': functionLabel(),
   |     |    <String>: stringLabel(),
   |     |    <Number>: numberLabel()
   |    },
   |    default: instruction()
  }
]]

--* StatementParser *--
local StatementParser = {};
function StatementParser:identifier()
  local identifierValue = self.curToken.Value
  local nextToken = self:peek()
  if self:compareToken(nextToken, "Character", ":") then
    self:consume() -- Consume the label name
    self:consume() -- Consume the colon
    return self:label(identifierValue)
  end
  return self:instruction()
end

function StatementParser:label(labelName)
  if self:compareToken(self.curToken, "Character", "{") then
    return self:labelFunction(labelName)
  elseif self:compareToken(self.curToken, "String") then
    return self:labelString(labelName)
  elseif self:compareToken(self.curToken, "Number") then
    return self:labelNumber(labelName)
  end
  return error("Invalid token: " .. tostring(self.curToken.TYPE))
end

function StatementParser:labelFunction(labelName)
  local Parser = ModuleManager:loadModule("Assembler/Parser/Parser")

  self:consume() -- Consume "{"
  -- Get nodes between curly braces
  local functionTokens = {}
  while self.curToken and not self:compareToken(self.curToken, "Character", "}") do
    insert(functionTokens, self.curToken)
    self:consume()
  end
  self:expectCurToken("Character", "}", true, "Unexpected function end")
  -- Copy current labels and constants
  local labelsCopy = copyTable(self.labels)
  local constantsCopy = copyTable(self.luaState.constants)
  -- Make a new assembly parser instance
  local newAssemblyParser = Parser:new(functionTokens)
  -- Share copied labels and constants with the new assembly parser instance
  newAssemblyParser.labels = labelsCopy
  newAssemblyParser.luaState.constants = constantsCopy
  local proto = newAssemblyParser:parse()
  insert(self.luaState.protos, proto)
  self.labels[labelName] = #self.luaState.protos
end

function StatementParser:labelString(labelName)
  local stringValue = self.curToken.Value
  self.labels[labelName] = self:findOrCreateConstant(tostring(stringValue))
end

function StatementParser:labelNumber(labelName)
  local numberValue = self.curToken.Value
  self.labels[labelName] = self:findOrCreateConstant(tonumber(numberValue))
end

function StatementParser:instructionParams()
  local params = { }
  local function insertParam(token)
    local tokenValue = token.Value
    local tokenType = token.TYPE
    if tokenType == "Identifier" then
      tokenValue = self.labels[tokenValue]
    elseif tokenType == "String" then
      tokenValue = self:findOrCreateConstant(tokenValue)
    end
    insert(params, tonumber(tokenValue) or 0)
  end

  -- Each instruction requires at least one param
  insertParam(self.curToken)
  local nextChar = self:peek()
  if self:compareToken(nextChar, "Character", ",") then
    self:consume() -- Consume the first param
    self:consume() -- Consume the comma

    -- Get params if they're separated by a comma
    repeat
      insertParam(self.curToken)
    until not (self:compareToken(self:peek(), "Character", ",") and self:consume(2) )
  end

  return params
end

function StatementParser:instruction()
  local instructionName = self.curToken.Value
  self:consume() -- Consume instruction name
  local params = self:instructionParams()
  insert(self.luaState.instructions, {instructionName, unpack(params)})
end

return StatementParser