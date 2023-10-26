--[[
  Name: VirtualMachine.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("VirtualMachine/VirtualMachine")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local InstructionFunctionality = ModuleManager:loadModule("VirtualMachine/InstructionFunctionality")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

local CreateTableDecorator = Helpers.CreateTableDecorator
local abs = math.abs
local insert = table.insert

--* VirtualMachine *--
local VirtualMachine = {}
function VirtualMachine:new(luaState, debug)
  local VirtualMachineInstance = {}

  local newConstants = {}
  for i,v in pairs(luaState.constants) do
    newConstants[-abs(i)] = v
  end
  luaState.constants = newConstants

  VirtualMachineInstance.debug = debug
  VirtualMachineInstance.InstructionFunctions = InstructionFunctionality:new(luaState, VirtualMachineInstance)
  VirtualMachineInstance.pc = 1
  VirtualMachineInstance.state = luaState
  VirtualMachineInstance.stackTrace = false
  VirtualMachineInstance.stackTraceTb = nil

  function VirtualMachineInstance:executeInstruction(instruction)
    local OPName, A, B, C = unpack(instruction)
    local instructionFunction = self.InstructionFunctions[OPName]
    instructionFunction(A, B, C)
    self.pc = self.pc + 1
  end
  function VirtualMachineInstance:handler(...)
    local luaState = self.state
    luaState.vararg = luaState.vararg or {...}

    local instructions = luaState.instructions
    while true do
      local currentInstruction = instructions[self.pc]
      if not currentInstruction then break end
      self:executeInstruction(currentInstruction)
    end

    self:stopStackTrace()
    return unpack(self.returnValues or {})
  end;

  function VirtualMachineInstance:constantDump()
    print("*--------Called constant dump--------*")
    Helpers.PrintTable(self.state.constants)
  end
  function VirtualMachineInstance:registerDump()
    print("*--------Called register dump--------*")
    Helpers.PrintTable(self.state.register)
  end

  function VirtualMachineInstance:startStackTrace()
    if self.stackTrace then return end

    self.stackTrace = true
    self.stackTraceTb = { _Index = {}, _NewIndex = {}, Instructions = {} }

    local VMSelf = self
    local stackTraceTb = self.stackTraceTb
    local originalRegister = self.state.register
    local registerDecorator = CreateTableDecorator(originalRegister)

     registerDecorator:__AddEvent("Index", function(self, index)
      local state = VMSelf.state
      local register = state.register
      local instructions = state.instructions
      local pc = VMSelf.pc
      local returnValue = originalRegister[index]

      local information = {
        instruction      = instructions[pc],
        instructionIndex = pc,
        registerIndex    = index,
        returnValue      = returnValue,
       }
      insert(stackTraceTb._Index, information)
    end)
    registerDecorator:__AddEvent("NewIndex", function(self, index, value)
      local state = VMSelf.state
      local register = state.register
      local instructions = state.instructions
      local pc = VMSelf.pc
      local oldValue = originalRegister[index]

      local information = {
        instruction      = instructions[pc],
        instructionIndex = pc,
        registerIndex    = index,
        oldValue         = returnValue,
        newValue         = value
       }
      insert(stackTraceTb._NewIndex, information)
    end)

    self.InstructionFunctions:updateRegister(registerDecorator)
  end
  function VirtualMachineInstance:stopStackTrace()
    if not self.stackTrace then return end

    self.stackTrace = false
    self.InstructionFunctions:updateRegister(self.state.register.__OriginalTable)
    local stackTraceTb = self.stackTraceTb

    print("Register._index:")
    for _, value in ipairs(stackTraceTb._Index) do
      print("  OPName: "            .. value.instruction[1])
      print("  A: "                 .. tostring(value.instruction[2]))
      print("  B: "                 .. tostring(value.instruction[3]))
      print("  C: "                 .. tostring(value.instruction[4]))
      print("  Instruction index: " .. tostring(value.instructionIndex))
      print("  Register index: "    .. value.registerIndex)
      print("  Return value: "      .. tostring(value.returnValue))
      print("------------------------------------")
    end
    print("Register._newindex:")
    for _, value in ipairs(stackTraceTb._NewIndex) do
      print("  OPName: "            .. value.instruction[1])
      print("  A: "                 .. tostring(value.instruction[2]))
      print("  B: "                 .. tostring(value.instruction[3]))
      print("  C: "                 .. tostring(value.instruction[4]))
      print("  Instruction index: " .. tostring(value.instructionIndex))
      print("  Register index: "    .. value.registerIndex)
      print("  Old value: "         .. tostring(value.oldValue))
      print("  New value: "         .. tostring(value.newValue))
      print("------------------------------------")
    end
    self.stackTraceTb = nil
  end

  function VirtualMachineInstance:run(...)
    if self.debug then self:startStackTrace() end

    local superSelf = self
    local returnValue = {}
    xpcall(function(...)
      returnValue = { self:handler(...) }
    end, function(...)
      superSelf:stopStackTrace()
      superSelf:registerDump()
      return print("Error while running virtual machine:", ...)
    end, ...)
    if self.debug then
      self:registerDump()
      self:constantDump()
      self:stopStackTrace()
    end

    return unpack(returnValue)
  end;

  return VirtualMachineInstance
end

return VirtualMachine