--[[
  Name: LuaState.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("LuaState/LuaState")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local PrintTable = Helpers.PrintTable

local defaultEnvironment = getfenv()

-- * LuaState * --
local LuaState = {}
function LuaState:new(instructions, constants, upvalues, env, register, protos, vararg, parameters, top)
  local LuaStateObject = {}

  LuaStateObject.instructions = instructions or {}
  LuaStateObject.constants = constants or {}
  LuaStateObject.upvalues = upvalues or {}
  LuaStateObject.env = env or defaultEnvironment
  LuaStateObject.register = register or {}
  LuaStateObject.protos = protos or {}
  LuaStateObject.vararg = vararg or {}
  LuaStateObject.parameters = parameters or {}
  LuaStateObject.top = top or 0

  function LuaStateObject:dumpState()
    local tbToAlign = {}
    for index, instruction in ipairs(self.instructions) do
      local newTb = {index}
      for index2, value in ipairs(instruction) do
        insert(newTb, " ")
        insert(newTb, value)
      end
      insert(tbToAlign, newTb)
    end
    print("Instructions: ")
    Helpers.PrintAligned(tbToAlign)

    local constantAlignTb = {}
    for index = 1, #self.constants do
      insert(constantAlignTb, {index, " ", self.constants[index]})
    end
    print("\nConstants: ")
    Helpers.PrintAligned(constantAlignTb)
  end

  return LuaStateObject
end

return LuaState