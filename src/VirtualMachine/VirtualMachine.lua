--[[
  Name: VirtualMachine.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-14
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local InstructionFunctionality = require("VirtualMachine/InstructionFunctionality")
local LuaState = require("LuaState/LuaState")

--* Imports *--
local abs = math.abs
local insert = table.insert
local unpack = (unpack or table.unpack)

--* VirtualMachineMethods *--
local VirtualMachineMethods = {}

function VirtualMachineMethods:executeInstruction(instruction)
  local OPName, A, B, C = instruction[1], instruction[2], instruction[3], instruction[4]
  local instructionFunction = self.instructionFunctions[OPName]
  instructionFunction(self, A, B, C)
  self.pc = self.pc + 1
end

function VirtualMachineMethods:constantDump()
  print("*--------Called constant dump--------*")
  Helpers.printTable(self.constants)
end
function VirtualMachineMethods:registerDump()
  print("*--------Called register dump--------*")
  Helpers.printTable(self.register1)
end

function VirtualMachineMethods:handler(...)
  local proto = self.proto
  local register = self.register
  local vararg = self.vararg
  local numParams = self.proto.numParams

  local handlerVararg = {...}
  local handlerVarargLength = select("#", ...) - 1

  for varargIndex = 0, handlerVarargLength do
    if (varargIndex >= numParams) then
      -- It's a vararg
      vararg[varargIndex - numParams] = handlerVararg[varargIndex + 1]
    else
      -- Argument. Put it in the stack
      stack[varargIndex] = handlerVararg[varargIndex + 1]
    end
  end

  local instructions = proto.instructions
  while true do
    local currentInstruction = instructions[self.pc]
    if not currentInstruction then break end
    self:executeInstruction(currentInstruction)
  end

  return unpack(self.returnValues or {})
end

function VirtualMachineMethods:saveCurrentState()
  local state = {}
  state.pc = self.pc
  state.proto = self.proto
  state.constants = self.constants
  state.register = self.register
  state.upvalues = self.upvalues
  state.protos = self.protos
  state.env = self.env
  return state
end

function VirtualMachineMethods:restoreState(state)
  self.pc = state.pc
  self.proto = state.proto
  self.constants = state.constants
  self.register = state.register
  self.upvalues = state.upvalues
  self.protos = state.protos
  self.env = state.env
end

function VirtualMachineMethods:runProto(proto, ...)
  local oldProto = self.proto

  local oldPC = self.pc
  self.pc = 1
  self.proto = proto
  self.constants = proto.constants
  self.register = proto.register
  self.upvalues = proto.upvalues
  self.protos = proto.protos
  self.env = self.state.env

  local returnValues = { self:handler(...) }

  self.proto = oldProto
  self.constants = oldProto.constants
  self.register = oldProto.register
  self.upvalues = oldProto.upvalues
  self.protos = oldProto.protos
  self.env = self.state.env
  self.pc = oldPC

  return unpack(returnValues)
end

function VirtualMachineMethods:run(...)
  return self:runProto(self.proto, ...)
end

--* VirtualMachine *--
local VirtualMachine = {}

--- Creates a new instance of the VirtualMachine class.
--- @param proto The prototype to run.
--- @param debug Whether to enable debugging or not.
--- @return VirtualMachine The new instance of the VirtualMachine class.
function VirtualMachine:new(proto, debug)

  local VirtualMachineInstance = {}
  VirtualMachineInstance.debug = debug
  VirtualMachineInstance.instructionFunctions = {} -- Will be set later

  VirtualMachineInstance.pc = 1

  VirtualMachineInstance.proto = proto
  VirtualMachineInstance.state = LuaState:new()
  VirtualMachineInstance.stackTrace = false
  VirtualMachineInstance.stackTraceTb = nil

  local function inheritModule(moduleName, moduleTable, field)
    for index, value in pairs(moduleTable) do
      if VirtualMachineInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and VirtualMachineInstance: " .. index)
      end
      if field then
        VirtualMachineInstance[field][index] = value
      else
        VirtualMachineInstance[index] = value
      end
    end
  end

  -- Main
  inheritModule("VirtualMachineMethods", VirtualMachineMethods)

  -- InstructionFunctionality
  inheritModule("InstructionFunctionality", InstructionFunctionality, "instructionFunctions")

  return VirtualMachineInstance
end

return VirtualMachine