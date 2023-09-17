--[[
  Name: LuaState.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("LuaState/LuaState")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local PrintTable = Helpers.PrintTable

local defaultEnvironment = getfenv()

-- * LuaState * --
local LuaState = {}
function LuaState.new(self, instructions, constants, upvalues, env, register, protos, vararg)
  local LuaStateObject = {}

  LuaStateObject.instructions = instructions or {}
  LuaStateObject.constants = constants or {}
  LuaStateObject.upvalues = upvalues or {}
  LuaStateObject.env = env or defaultEnvironment
  LuaStateObject.register = register or {}
  LuaStateObject.protos = protos or {}
  LuaStateObject.vararg = vararg or {}

  function LuaStateObject:printState()
    print('-----------------------')
    print("Instructions:")
    PrintTable(self.instructions)
    print('-----------------------')
    print("Constants:")
    PrintTable(self.constants)
    print('-----------------------')
    print("Protos:")
    for i,v in pairs(self.protos) do v:printState() end
  end

  return LuaStateObject
end

return LuaState