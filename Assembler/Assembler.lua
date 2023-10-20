--[[
  Name: Assembler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Assembler")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Lexer = ModuleManager:loadModule("Assembler/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Assembler/Parser/Parser")

--* Export library functions *--
local ReadFile = Helpers.ReadFile

--* Assembler *--
local Assembler = {}

function Assembler:tokenize(str)
  local tokens = Lexer:new(str):tokenize()
  return tokens
end
function Assembler:parse(tokens)
  local state = Parser:new(tokens):run()
  return state
end
function Assembler:assemble(str)
  local tokens = self:tokenize(str)
  local state = self:parse(tokens)
  return state
end

function Assembler:loadFile(filePath)
  return self:assemble(ReadFile(filePath))
end

return Assembler