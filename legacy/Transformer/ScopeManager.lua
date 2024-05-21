--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
  Description:
    This module is responsible for managing the scope of variables in the Transformer.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local remove = table.remove
local unpack = (unpack or table.unpack)

--* Class methods *--
local ScopeManagerMethods = {}
function ScopeManagerMethods:pushScope(isFunctionScope)
  local newScope = {
    locals = {},
    parent = self.currentScope,
    isFunctionScope = isFunctionScope or false,
  }

  self.currentScope = newScope
  self.scopes[#self.scopes + 1] = newScope
end

function ScopeManagerMethods:popScope()
  if self.currentScope then
    self.currentScope = self.currentScope.parent
    self.scopes[#self.scopes] = nil
  end
end

function ScopeManagerMethods:registerVariable(variableName, initialValue)
  local currentScope = self.currentScope
  if variableName == "..." then
    -- We don't use tables for the vararg, because it's a table itself
    currentScope.locals[variableName] = initialValue
    return
  end

  -- We use tables, so the variable blinding bug won't occur
  currentScope.locals[variableName] = { initialValue }
end

function ScopeManagerMethods:checkVariable(variableName)
  local currentScope = self.currentScope
  local isUpvalue = false

  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      if isUpvalue then return "Upvalue" end
      return "LocalVariable"
    end
    if currentScope.isFunctionScope then
      isUpvalue = true
    end

    currentScope = currentScope.parent
  end
  return "GlobalVariable"
end

--* ScopeManager *--
local ScopeManager = {}
function ScopeManager:new()
  local ScopeManagerInstance = {}
  ScopeManagerInstance.scopes = {}
  ScopeManagerInstance.currentScope = { locals = {} }

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ScopeManagerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ScopeManagerInstance: " .. index)
      end
      ScopeManagerInstance[index] = value
    end
  end

  -- Main
  inheritModule("ScopeManagerMethods", ScopeManagerMethods)

  return ScopeManagerInstance
end

return ScopeManager