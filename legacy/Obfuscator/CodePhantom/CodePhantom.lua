--[[
  Name: CodePhantom.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-03
  Description:
    This obfuscator is the most powerful obfuscator in the world.
    It will be a ghost of its former self.
    uwu >:3 I am a ghost! uwu >:3
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Instructions = require("Obfuscator/CodePhantom/Instructions/Instructions")
local MockingStrings = require("Obfuscator/CodePhantom/MockingStrings")

--* Import library functions *--
local abs = math.abs
local find = (table.find or Helpers.tableFind)
local insert = table.insert
local concat = table.concat
local floor = math.floor
local random = math.random


--* Constants *--
local signature = [=[
--[[
  Shitficated with CodePhantom
  I am a ghost! uwu >:3
--]]
]=]

--* CodePhantomMethods *--
local CodePhantomMethods = {}

function CodePhantomMethods:obfuscateAddition(expectedResult)
  local randomNumberA = random(-2147483648, 2147483647)
  local randomNumberB = expectedResult - randomNumberA
  return randomNumberA .. " + " .. randomNumberB
end

function CodePhantomMethods:obfuscateSubtraction(expectedResult)
  local randomNumberA = random(-2147483648, 2147483647)
  local randomNumberB = randomNumberA + expectedResult
  return randomNumberB .. " - " .. randomNumberA
end

function CodePhantomMethods:obfuscateModulo(expectedResult)
  local randomNumberA = random(1, 6553)
  local randomNumberB = random(1, 6553)
  return ((randomNumberA * randomNumberB) + expectedResult ) .. " % " .. randomNumberA
end

function CodePhantomMethods:obfuscateStringLength(expectedResult)
  local randomMockingString = self.mockingStrings[random(1, #self.mockingStrings)]
  local randomMockingStringLen = #randomMockingString
  return "#\"" .. randomMockingString .. "\" + " .. (expectedResult - randomMockingStringLen)
end

function CodePhantomMethods:obfsucateInteger(expectedResult)
  local randomOperatorNumber = random(1, 4)
  if randomOperatorNumber == 1 then
    return self:obfuscateAddition(expectedResult)
  elseif randomOperatorNumber == 2 then
    return self:obfuscateSubtraction(expectedResult)
  elseif randomOperatorNumber == 3 then
    return self:obfuscateModulo(expectedResult)
  elseif randomOperatorNumber == 4 then
    return self:obfuscateStringLength(expectedResult)
  end
end

function CodePhantomMethods:ObfuscateFloat(expectedResult)
  local randomOperatorNumber = random(1, 3)
  if randomOperatorNumber == 1 then
    return self:obfuscateAddition(expectedResult)
  elseif randomOperatorNumber == 2 then
    return self:obfuscateSubtraction(expectedResult)
  elseif randomOperatorNumber == 3 then
    return self:obfuscateStringLength(expectedResult)
  end
end

function CodePhantomMethods:obfuscateNumber(expectedResult)
  if floor(expectedResult) == expectedResult then
    return self:obfsucateInteger(expectedResult)
  end
  return self:ObfuscateFloat(expectedResult)
end

function CodePhantomMethods:addLine(line)
  self.script = self.script .. line .. "\n"
end
function CodePhantomMethods:makeGhost()
  -- Ghost signature
  self:addLine(signature)
end
function CodePhantomMethods:getInstructionCode(instruction)
  local instructionName = instruction[1]
  local instructionFunction = self.instructions[instructionName]
  if instructionFunction then
    return instructionFunction(self, instruction[2], instruction[3], instruction[4])
  else
    return "--[[ Unknown instruction: " .. instructionName .. " ]]"
  end
end
function CodePhantomMethods:compileInstructions(instructions)
  for _, instruction in ipairs(instructions) do
    self:addLine(self:getInstructionCode(instruction))
  end
end
function CodePhantomMethods:run()
  local newConstants = {}
  -- Normalize the constants table
  -- all constants are stored in the negative indices
  for i,v in pairs(self.state.constants) do
    newConstants[-abs(i)] = v
  end
  self.state.constants = newConstants

  self:makeGhost()
  self:compileInstructions(self.state.instructions)
  return self.script
end

function CodePhantomMethods:generateRandomVariableName()
  local dict = {
    "uwu", "Uwu", "uwU", "UwU",
    "owo", "Owo", "owO", "OwO"
  }
  while true do
    local randomName = ""
    for i = 1, math.random(5, 10) do
      randomName = randomName .. dict[math.random(1, #dict)]
    end
    if not find(self.variables, randomName) then
      return randomName
    end
  end
end

function CodePhantomMethods:registerRegisterVariable(registerNumber)
  if self.variables[registerNumber] then
    return self.variables[registerNumber]
  end

  local variableName = self:generateRandomVariableName()
  local variable = {
    Name = variableName,
    IsSet = false
  }
  self.variables[registerNumber] = variable
  return variable
end

--* CodePhantom *--
local CodePhantom = {}
function CodePhantom:new(luaState)
  local CodePhantomInstance = {}
  CodePhantomInstance.state = luaState
  CodePhantomInstance.script = ""
  CodePhantomInstance.instructions = Instructions
  CodePhantomInstance.variables = {}
  CodePhantomInstance.mockingStrings = MockingStrings

  for index, func in pairs(CodePhantomMethods) do
    CodePhantomInstance[index] = func
  end

  return CodePhantomInstance
end

return CodePhantom