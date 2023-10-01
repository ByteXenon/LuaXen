--[[
  Name: Decompiler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Decompiler/Decompiler")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local find = Helpers.FindTable
local insert = table.insert
local concat = table.concat

-- * Decompiler * --
local Decompiler;
function Decompiler:new(state)
  local DecompilerInstance = {};

end

return Decompiler