--[[
  Name: Factory.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Transpiler/lua/Factory")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local LuaTranspiler = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/lua/Transpiler")
local Templates = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/lua/Templates")

--* Export library functions *--
local Class = Helpers.NewClass

--* LuaTranspilerFactory *--
local LuaTranspilerFactory = Class{
  BuildTranspiler = function(self, AST, templates)
    local templates = templates or Templates
    local newLuaTranspiler = LuaTranspiler(AST)
    
    for index, value in pairs(templates) do
      newLuaTranspiler[index .. "Template"] = value
    end;
    
    return newLuaTranspiler
  end;
}

return LuaTranspilerFactory