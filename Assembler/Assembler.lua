--[[
  Name: Assembler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Assembler")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
-- here it imports the tokenizer
-- to later use it
local Lexer = ModuleManager:loadModule("Assembler/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Assembler/Parser/Parser")

--* Export library functions *--
local ReadFile = Helpers.ReadFile

--* Assembler *--
local Assembler = {}

function Assembler:assemble(str)
  local tokens = Lexer:new(str):tokenize()
  local state = Parser:new(tokens):run()
  return state
end

-- Load given file, assemble, and return a Lua state
function Assembler:loadFile(filePath)
  return self:assemble(ReadFile(filePath))
end

return Assembler