--[[
  Name: VirtualMachine.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
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
function VirtualMachine:new(luaState)
  local VirtualMachineInstance = {}

  local newConstants = {}
  for i,v in pairs(luaState.constants) do
    newConstants[-abs(i)] = v
  end
  luaState.constants = newConstants
  
  VirtualMachineInstance.InstructionFunctions = InstructionFunctionality:new(luaState, VirtualMachineInstance)
  VirtualMachineInstance.pc = 1
  VirtualMachineInstance.state = luaState
  VirtualMachineInstance.stackTrace = false
  VirtualMachineInstance.stackTraceTb = nil

  function VirtualMachineInstance:handler(...)
    local luaState = self.state
    
    luaState.vararg = luaState.vararg or {...}
    local instructions = luaState.instructions
    local instructionFunctions = self.InstructionFunctions

    local currentPC = self.pc
    while true do
      local currentInstruction = instructions[currentPC]
      if not currentInstruction then break end

      local OPName, A, B, C = unpack(currentInstruction)
      local instructionFunction = instructionFunctions[OPName]
      self.pc = currentPC
      instructionFunction(A, B, C)
      currentPC = self.pc + 1
    end
    
    self:stopStackTrace()
    return unpack(self.returnValues or {})
  end;

  function VirtualMachineInstance:constantDump()
    print("*--------Called constant dump--------*")
    Helpers.PrintTable(self.state.constants)
    print("*------------------------------------*")
  end
  function VirtualMachineInstance:registerDump()
    print("*--------Called register dump--------*")
    Helpers.PrintTable(self.state.register)
    print("*------------------------------------*")
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
        instruction = instructions[pc],
        instructionIndex = pc,
        registerIndex = index,
        returnValue = returnValue,
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
        instruction = instructions[pc],
        instructionIndex = pc,
        registerIndex = index,
        oldValue = returnValue,
        newValue = value
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
    for Index, Value in ipairs(stackTraceTb._Index) do
      print("  OPName: "..Value.instruction[1])
      print("  A: "..tostring(Value.instruction[2]))
      print("  B: "..tostring(Value.instruction[3]))
      print("  C: "..tostring(Value.instruction[4]))
      print("  Instruction index: "..tostring(Value.instructionIndex))
      print("  Register index: "..Value.registerIndex)
      print("  Return value: "..tostring(Value.returnValue))
      print("------------------------------------")
    end
    print("Register._newindex:")
    for Index, Value in ipairs(stackTraceTb._NewIndex) do
        print("  OPName: "..Value.instruction[1])
        print("  A: "..tostring(Value.instruction[2]))
        print("  B: "..tostring(Value.instruction[3]))
        print("  C: "..tostring(Value.instruction[4]))
        print("  Instruction index: "..tostring(Value.instructionIndex))
        print("  Register index: "..Value.registerIndex)
        print("  Old value: "..tostring(Value.oldValue))
        print("  New value: "..tostring(Value.newValue))
        print("------------------------------------")
    end
    self.stackTraceTb = nil
  end

  function VirtualMachineInstance:run(...)
    local superSelf = self
    local returnValue = {}
    xpcall(function(...)
      returnValue = { self:handler(...) }
    end, function(...)
      superSelf:stopStackTrace()
      superSelf:registerDump()
      return print("Error while running virtual machine:", ...)
    end, ...)
    
    return unpack(returnValue)
  end;

  return VirtualMachineInstance
end

return VirtualMachine