--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is responsible for managing the scope of variables in the ASTExecutor.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
    It also keeps track of flags and contexts for node execution.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ScopeManager")
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
  self.scopes[#(self.scopes) + 1] = newScope
end

function ScopeManagerMethods:popScope()
  if self.currentScope then
    self.currentScope = self.currentScope.parent
    self.scopes[#(self.scopes)] = nil
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

function ScopeManagerMethods:getVariable(variableName, luaState)
  local currentScope = self.currentScope

  -- We need to check if the variable is in the current scope
  -- if not, we need to check the parent scope and so on
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      if variableName == "..." then
        return unpack(variable)
      end
      -- We use tables, so the variable is stored in the first index
      return variable[1]
    end
    currentScope = currentScope.parent
  end

  -- If the variable is not in any scope, we return the environment variable
  return luaState.env[variableName]
end

function ScopeManagerMethods:changeVariable(variableName, newValue, luaState)
  local currentScope = self.currentScope
  print(variableName)

  -- We need to check if the variable is in the current scope
  -- if not, we need to check the parent scope and so on
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      -- We use tables, so the variable blinding bug won't occur
      -- on variables that are equal to nil
      if variableName == "..." then
        -- We assume that newValue is a table
        currentScopeLocals[variableName] = newValue
        return
      end
      -- We **better not** make a new table each time we change a variable 
      variable[1] = newValue
      return
    end
    currentScope = currentScope.parent
  end

  -- If the variable is not in any scope, we change the environment variable
  luaState.env[variableName] = newValue
end

--* ScopeManager *--
local ScopeManager = {}
function ScopeManager:new(env)
  local ScopeManagerInstance = {}
  ScopeManagerInstance.scopes = {}
  ScopeManagerInstance.currentScope = { locals = {} }
  -- Since "return" affects entire function, we need to keep track of it globally
  -- The only thing is that we need to reset it after each function call
  -- We also need to keep track of "break" in loops.
  ScopeManagerInstance.globalFlags = {
    returnFlag = false,
    breakFlag = false,
    continueFlag = false
  }

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ScopeManagerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ScopeManagerInstance: " .. index)
      end
      ScopeManagerInstance[index] = value
    end
  end

  inheritModule("ScopeManagerMethods", ScopeManagerMethods)

  return ScopeManagerInstance
end

return ScopeManager