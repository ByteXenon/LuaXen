--[[
  Name: ScopeManager.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is responsible for managing the scope of variables in the InstructionGenerator.
    It provides methods for pushing and popping scopes, registering, getting, and changing variables.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/ScopeManager")
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

function ScopeManagerMethods:registerVariable(variableName, register)
  local currentScope = self.currentScope
  currentScope.locals[variableName] = register
end

function ScopeManagerMethods:getLocalRegister(variableName)
  local currentScope = self.currentScope
  while currentScope do
    local currentScopeLocals = currentScope.locals
    local variable = currentScopeLocals[variableName]

    if variable then return variable end

    currentScope = currentScope.parent
  end

  return nil
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