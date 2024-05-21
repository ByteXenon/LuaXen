--[[
  Name: LuaState.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-03
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Constants *--
-- Lua5.1- vs Lua5.1+ shenanigans
local defaultEnvironment = (_ENV or (getfenv and getfenv()) or _G)

-- * LuaState * --
local LuaState = {}
function LuaState:new()
  local LuaStateObject = {}

  LuaStateObject.instructions = {}
  LuaStateObject.constants = {}
  LuaStateObject.upvalues = {}
  LuaStateObject.env = defaultEnvironment
  LuaStateObject.register = {}
  LuaStateObject.protos = {}
  LuaStateObject.vararg = {}
  LuaStateObject.parameters = {}
  LuaStateObject.top = 0

  return LuaStateObject
end

return LuaState