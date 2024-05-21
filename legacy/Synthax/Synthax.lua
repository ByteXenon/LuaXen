--[[
  Name: Synthax.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/05/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Synthax")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ASTGenerator = ModuleManager:loadModule("Interpreter/Synthax/ASTGenerator/ASTGenerator")
local Tokenizer = ModuleManager:loadModule("Interpreter/Synthax/Tokenizer/Tokenizer")
local Transpiler = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/Transpiler")

--* Imports *--
local Class = Helpers.NewClass

--* Synthax *--
local Synthax = Class{
  ASTGenerator = ASTGenerator,
  Tokenizer = Tokenizer,
  Transpiler = Transpiler
}

return Synthax