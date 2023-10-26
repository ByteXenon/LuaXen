--[[
  Name: LuaDumpToAssemblyConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/??/XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("LuaState/LuaState")
local OPCodes = require("OPCodes/OPCodes")
local Assembler = require("Assembler/Assembler")

--* Export library functions *--
local Class = Helpers.NewClass
local StringToTable = Helpers.StringToTable
local FormattedError = Helpers.FormattedError
local GetLines = Helpers.GetLines
local find = Helpers.FindTable
local insert = table.insert
local concat = table.concat
local gsub = string.gsub
local byte = string.byte
local char = string.char
local rep = string.rep


-- * LuaDumpToAssemblyConverter * --
local LuaDumpToAssemblyConverter = {}
function LuaDumpToAssemblyConverter:convert(string)
  local state = LuaState:new()

  local unconvertedInstructions = GetLines(string:match("functions(.-)constants %(%d+%)"):sub(2, -2))
  for _, str in pairs(unconvertedInstructions) do
    OPName, A, B, C = str:match("(%a+)%s*(%-?%d*)%s*(%-?%d*)%s*(%-?%d*)")
    A, B, C = tonumber(A), tonumber(B), tonumber(C)
    
    insert(state.instructions, {OPName, A, B, C})
  end

  local unconvertedConstants = GetLines(string:match("%d+:(.-)locals"):sub(2, -2))
  for _, str in pairs(unconvertedConstants) do
    str = str:match("%d+%s+(.+)")
    if str == "false" or str == "true" then
      insert(state.constants, str == "true")
    elseif tonumber(str) then
      insert(state.constants, tonumber(str))
    else
      insert(state.constants, str:match('^(%b"")$'))
    end
  end

  Helpers.PrintTable(state)
end;

return LuaDumpToAssemblyConverter