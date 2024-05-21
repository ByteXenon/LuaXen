--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-03
  Description:
    This module is responsible for managing the scope of variables in the ASTExecutor.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
    It also keeps track of flags and contexts for node execution.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local remove = table.remove
local unpack = (unpack or table.unpack)

--* Class methods *--
local ScopeManager = {}

function ScopeManager:pushScope(isFunctionScope)
  local newScope = {
    locals = {},
    parent = self.currentScope,
    isFunctionScope = isFunctionScope
  }

  self.currentScope = newScope
  self.scopes[#self.scopes + 1] = newScope
end

function ScopeManager:popScope()
  if self.currentScope then
    self.currentScope = self.currentScope.parent
    self.scopes[#self.scopes] = nil
    return
  end

  return error("Attempt to pop scope when there is no scope")
end

function ScopeManager:registerVariable(variableName, initialValue)
  local currentScope = self.currentScope
  if variableName == "..." then
    -- We don't use tables for the vararg, because it's a table itself
    currentScope.locals[variableName] = initialValue
    return
  end
  -- We use tables, so the variable blinding bug won't occur
  currentScope.locals[variableName] = { initialValue }
end

function ScopeManager:getVarArg()
  local currentScope = self.currentScope
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals["..."]
    if variable then
      return unpack(variable)
    end

    currentScope = currentScope.parent
  end

  -- If the variable is not in any local scope, return nil
  return nil
end

function ScopeManager:getUpvalue(variableName)
  local currentScope = self.currentScope

  -- We need to check if the variable is in the current scope
  -- if not, we need to check the parent scope and so on
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      -- We use tables, so the variable is stored in the first index
      return variable[1]
    end
    currentScope = currentScope.parent
  end

  -- If the variable is not in any local scope, return nil
  return nil
end

function ScopeManager:getLocalVariable(variableName)
  local currentScope = self.currentScope

  -- We need to check if the variable is in the current scope
  -- if not, we need to check the parent scope and so on
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      -- We use tables, so the variable is stored in the first index
      return variable[1]
    end
    currentScope = currentScope.parent
  end

  -- If the variable is not in any local scope, return nil
  return nil
end

function ScopeManager:getGlobalVariable(variableName)
  -- If the variable is not in any local scope, we return the environment variable
  return self.state.globalEnvironment[variableName]
end

function ScopeManager:getVariable(variableName)
  local variable = self:getLocalVariable(variableName)
  if variable then
    return variable
  end
  return self:getGlobalVariable(variableName)
end

function ScopeManager:changeVariable(variableName, newValue)
  local currentScope = self.currentScope

  -- We need to check if the variable is in the current scope
  -- if not, we need to check the parent scope and so on
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then
      -- We **better not** make a new table each time we change a variable
      variable[1] = newValue
      return
    end
    currentScope = currentScope.parent
  end

  -- print("[Warning] Changing global variable: " .. variableName)
  -- If the variable is not in any scope, we change the environment variable
  self.state.globalEnvironment[variableName] = newValue
end

return ScopeManager