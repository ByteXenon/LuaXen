--[[
  Name: Transpiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Transpiler/Transpiler")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--local LuaTranspilerFactory = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/lua/Factory")
local LuaTranspiler = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/lua/Transpiler2")

--* Export library functions *--
local Class = Helpers.NewClass

--* Transpiler *--
local Transpiler = {
  --LuaTranspilerFactory = LuaTranspilerFactory;
  LuaTranspiler = LuaTranspiler;
}

return Transpiler