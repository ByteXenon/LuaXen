--[[
  Name: StaticAnalyzer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("StaticAnalyzer/StaticAnalyzer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")
local AbstractDomain = ModuleManager:loadModule("StaticAnalyzer/AbstractDomain")

local insert = table.insert

--* StaticAnalyzer *--
local StaticAnalyzer = {}
function StaticAnalyzer:new()
  local StaticAnalyzerInstance = {}

  

  return StaticAnalyzerInstance
end

return StaticAnalyzer