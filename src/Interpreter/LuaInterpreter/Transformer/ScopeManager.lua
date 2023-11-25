--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is responsible for managing the scope of variables in the Transformer.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Transformer/ScopeManager")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local remove = table.remove
local unpack = (unpack or table.unpack)

--* Class methods *--
local ScopeManagerMethods = {}
function ScopeManagerMethods:pushScope()
  local newScope = {
    locals = {},
    parent = self.currentScope,
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

  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      if currentScope == self.currentScope then
        return "LocalVariable"
      end

      return "Upvalue"
    end
    currentScope = currentScope.parent
  end

  -- It's a global variable
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