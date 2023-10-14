--[[
  Name: ScopeState.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/ScopeState")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* ScopeState *--
local ScopeState = {}
function ScopeState:new(luaState, instructionGenerator, scopeState)
  local ScopeStateInstance = {}
  ScopeStateInstance.luaState = luaState
  ScopeStateInstance.instructionGenerator = instructionGenerator
  ScopeStateInstance.locals = {}
  ScopeStateInstance.protos = {}

  if scopeState then
    for i,v in pairs(scopeState.locals) do
      ScopeStateInstance.locals[i] = v
    end
    for i,v in pairs(scopeState.protos) do
      ScopeStateInstance.protos[i] = v
    end
  end

  function ScopeStateInstance:addLocal(localName)
    if self.locals[localName] then return self.locals[localName] end
    local allocatedRegister = self.instructionGenerator:allocateRegister()
    self.locals[localName] = allocatedRegister
    return allocatedRegister
  end;
  function ScopeStateInstance:addProto(protoName, proto)
    self[protoName] = proto
  end

  function ScopeStateInstance:setLocal(register, localName)
    self.locals[localName] = register
    self.luaState[register] = true -- Take it for the local variable
    return register
  end
  function ScopeStateInstance:findLocal(localName)
    return self.locals[localName]
  end

  return ScopeStateInstance
end

return ScopeState