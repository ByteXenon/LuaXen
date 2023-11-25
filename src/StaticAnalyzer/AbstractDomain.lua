--[[
  Name: AbstractDomain.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("StaticAnalyzer/AbstractDomain")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local insert = table.insert

--* AbstractDomain *--
local AbstractDomain = {}
