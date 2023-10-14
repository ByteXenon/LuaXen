--[[
  Name: example.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("example.lua")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local ASTToTokensConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")
local Beautifier = ModuleManager:loadModule("Beautifier/Beautifier")
local Minifier = ModuleManager:loadModule("Minifier/Minifier")
local ASTExecutor = ModuleManager:loadModule("ASTExecutor/ASTExecutor")
local ASTObfuscator = ModuleManager:loadModule("Obfuscator/ASTObfuscator/ASTObfuscator")

local code = [=[
local a = 1 + 2 / (2 * 8)
print(a)
]=]


local tokens = Lexer:new(code):tokenize()
Helpers.PrintTable(tokens)
local AST = Parser:new(tokens):parse()
--local obfuscatedAST = ASTObfuscator:new(AST):run() 
--print(Beautifier:new(AST):run())
print(Minifier:new(ASTToTokensConverter:new(AST):run()):run())
--ASTExecutor:new(obfuscatedAST):execute()