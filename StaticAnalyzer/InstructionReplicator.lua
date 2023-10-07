--[[
  Name: InstructionReplicator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("StaticAnalyzer/InstructionReplicator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local LuaState = ModuleManager:loadModule("LuaState/LuaState")
local InstructionFunctionality = ModuleManager:loadModule("VirtualMachine/InstructionFunctionality")

--* InstructionReplicator *--
local InstructionReplicator = {}
function InstructionReplicator:new()
  local InstructionReplicatorInstance = {}
  InstructionReplicatorInstance.state = LuaState:new()
  InstructionReplicatorInstance.replicatedRegister = {}
  InstructionReplicatorInstance.state.register = InstructionReplicatorInstance.replicatedRegister
  InstructionReplicatorInstance.InstructionFunctionality = InstructionFunctionality:new(InstructionReplicatorInstance.state)

  function InstructionReplicatorInstance:replicateInstruction(opname, a, b, c)
    self:InstructionFunctionality[opname](a, b, c)
  end
  
  return InstructionReplicatorInstance
end

return InstructionReplicator