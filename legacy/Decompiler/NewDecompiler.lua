--[[
  Name: NewDecompiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("LuaState/LuaState")
local InstructionRangeDecompiler = require("Decompiler/InstructionRangeDecompiler")

local concat = table.concat

-- * Decompiler * --
local Decompiler = {}
function Decompiler.decompile(self, state, indentation)
  local indentation = indentation or 0
  local decompiledProtos = {}
  for _, proto in ipairs(state.protos) do
    local decompiledCode = Decompiler:decompile(proto, indentation + 1)
    insert(decompiledProtos, decompiledCode)
  end

  return concat(InstructionRangeDecompiler.new():decompile(state.instructions, state.constants, {}, decompiledProtos, nil, nil, indentation), "\n")
end;

return Decompiler