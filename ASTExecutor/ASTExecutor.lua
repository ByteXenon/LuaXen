--[[
  Name: ASTExecutor.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ASTExecutor")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local ASTNodesFunctionality = ModuleManager:loadModule("ASTExecutor/ASTNodesFunctionality")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local insert = table.insert

local ASTExecutor = {}
function ASTExecutor:new(AST, state)
  local luaState = state or LuaState:new()

  local ASTExecutorInstance = ASTNodesFunctionality:new({}) 
  ASTExecutorInstance.ast = AST
  ASTExecutorInstance.state = luaState
  ASTExecutorInstance.varArg = luaState.varArg
  ASTExecutorInstance.env = luaState.env
  ASTExecutorInstance.locals = {}
  ASTExecutorInstance.returnValues = nil

  function ASTExecutorInstance:setLocalVariable(localName, localValue)
    local locals = self.locals
    
    local localVariable = locals[localName]
    if not localVariable then
      localVariable = {}
      locals[localName] = localVariable
    end
    localVariable.Value = localValue
    return localVariable
  end
  function ASTExecutorInstance:getLocalValue(localName)
    local localVarible = self.locals[localName]
    if not localVariable then return end
    return localVarible.Value
  end
  function ASTExecutorInstance:getLocalVariablesValues(locals)
    local values = {}
    for _, localVariableName in ipairs(locals) do
      values[localVariableName] = self:getLocalValue(localVariableName)
    end
    return values
  end
  function ASTExecutorInstance:setLocalsValues(values)
    for localName, localTable in pairs(values) do
      self:setLocalVariable(localName, localTable.Value)
    end
  end
  function ASTExecutorInstance:copyLocals()
    local locals = {}
    for localName, localTable in pairs(self.locals) do
      locals[localName] = localTable
    end
    return locals
  end

  function ASTExecutorInstance:executeCodeBlock(nodeList)
    local oldLocals = self:copyLocals()

    for _, node in ipairs(nodeList) do
      self:executeNode(node, true)
      local returnValues = self.returnValues
      if returnValues then
        self.returnValues = nil
        return unpack(returnValues)
      end
    end

    self.locals = oldLocals
  end
  function ASTExecutorInstance:execute()
    return self:executeCodeBlock(self.ast)
  end

  return ASTExecutorInstance
end

return ASTExecutor