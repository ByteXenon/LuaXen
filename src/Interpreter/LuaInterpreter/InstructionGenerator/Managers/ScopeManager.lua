--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-08
  Description:
    This module is responsible for managing the scope of variables in the InstructionGenerator.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local remove = table.remove
local unpack = (unpack or table.unpack)
local tableLen = Helpers.tableLen

--* ScopeManager *--
local ScopeManager = {}

function ScopeManager:pushScope()
  local newScope = {
    locals = {},
    parent = self.currentScope,
  }

  self.currentScope = newScope
  self.scopes[#self.scopes + 1] = newScope
end

function ScopeManager:popScope()
  local currentScope = self.currentScope
  if currentScope then
    self.currentScope = currentScope.parent
    self.scopes[#self.scopes] = nil
    return
  end

  error("No scope to pop")
end

function ScopeManager:getRegisterVariable(register)
  return self.takenRegisters[register]
end

function ScopeManager:registerVariable(variableName, register)
  local currentScope = self.currentScope
  currentScope.locals[variableName] = register
  self.takenRegisters[register] = variableName
  self.currentProto.locals[variableName] = true
end

function ScopeManager:getLocalRegister(variableName)
  local currentScope = self.currentScope
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variableRegister = currentScopeLocals[variableName]

    if variableRegister then return variableRegister end
    currentScope = currentScope.parent
  end

  return nil
end

return ScopeManager