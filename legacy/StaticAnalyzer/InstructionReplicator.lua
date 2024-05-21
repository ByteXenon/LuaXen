--[[
  Name: InstructionReplicator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("LuaState/LuaState")

local InstructionFunctionality = require("VirtualMachine/InstructionFunctionality")

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