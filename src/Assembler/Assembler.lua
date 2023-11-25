--[[
  Name: Assembler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module contains the implementation of the Assembler class, 
    which is responsible for assembling Lua source code into bytecode (luaState). 
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

--- Tokenizes a string of Lua source code.
-- @param str The string of Lua source code to tokenize.
-- @return A table of tokens.
function Assembler:tokenize(str)
  local tokens = Lexer:new(str):tokenize()
  return tokens
end

--- Parses a table of tokens into a table representing the parsed state of the source code.
-- @param tokens A table of tokens.
-- @return A table representing the parsed state of the source code.
function Assembler:parse(tokens)
  local state = Parser:new(tokens):parse()
  return state
end

--- Assembles a string of Lua source code into bytecode.
-- @param str The string of Lua source code to assemble.
-- @return A table representing the parsed state of the source code.
function Assembler:assemble(str)
  local tokens = self:tokenize(str)
  local state = self:parse(tokens)
  return state
end

--- Loads a file containing Lua source code, assembles its contents, and returns the resulting state.
-- @param filePath The path to the file to load.
-- @return A table representing the parsed state of the source code.
function Assembler:loadFile(filePath)
  return self:assemble(ReadFile(filePath))
end

return Assembler