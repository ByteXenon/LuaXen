--[[
  Name: example.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("example.lua")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")
local Beautifier = ModuleManager:loadModule("Beautifier/Beautifier")

local code = [=[
  for i = 1, 10, 1 do
  for i,v in pairs({1}) do
  do
local a = (function(i)
  return function(a, b)
    print("Hello, world: ", a, b)
  end)
end)(i);
local b = a(1, 2)
end
end
end
]=]


local tokens = Lexer:new(code):tokenize()
local AST = Parser:new(tokens):parse()
print(Beautifier:new(AST):run())