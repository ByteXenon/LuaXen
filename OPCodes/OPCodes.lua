--[[
  Name: OPCodes.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Libraries *--
--local Binary = require("Binary/Main")
local Helpers = require("Helpers/Helpers")

--* Pre-index functions *--
local Insert = table.insert
local Concat = table.concat
local Floor = math.floor

--* Library object *--
local OPCodes = {}

OPCodes.OP_ENUM = {
  "MOVE",     "LOADK",     "LOADBOOL",  "LOADNIL",
  "GETUPVAL", "GETGLOBAL", "GETTABLE",  "SETGLOBAL",
  "SETUPVAL", "SETTABLE",  "NEWTABLE",  "SELF",
  "ADD",      "SUB",       "MUL",       "DIV",
  "MOD",      "POW",       "UNM",       "NOT",
  "LEN",      "CONCAT",    "JMP",       "EQ",
  "LT",       "LE",        "TEST",      "TESTSET",
  "CALL",     "TAILCALL",  "RETURN",    "FORLOOP",
  "FORPREP",  "TFORLOOP",  "SETLIST",   "CLOSE",
  "CLOSURE",  "VARARG",    "DEBUG"
}

-- Modes:
--  [0] A
--  [1] A, B
--  [2] A, Bx
--  [3] A, B, C
--  [4] sBx
--  [5] A, sBx

-- { [<InstructionName>] = { <ParamCount>, <Index>, <ParamMode> } }
OPCodes.OP_Table = {
  ["MOVE"]     =  {2, 1, 1},   ["LOADK"]     =  {2, 2, 2},   ["LOADBOOL"] =  {3, 3, 3},  ["LOADNIL"]   =  {2, 4, 1},
  ["GETUPVAL"] =  {2, 5, 1},   ["GETGLOBAL"] =  {2, 6, 2},   ["GETTABLE"] =  {3, 7, 3},  ["SETGLOBAL"] =  {2, 8, 2},
  ["SETUPVAL"] =  {2, 9, 1},   ["SETTABLE"]  =  {3, 10, 3},  ["NEWTABLE"] =  {3, 11, 3}, ["SELF"]      =  {3, 12, 3},
  ["ADD"]      =  {3, 13, 3},  ["SUB"]       =  {3, 14, 3},  ["MUL"]      =  {3, 15, 3}, ["DIV"]       =  {3, 16, 3},
  ["MOD"]      =  {3, 17, 3},  ["POW"]       =  {3, 18, 3},  ["UNM"]      =  {2, 19, 1}, ["NOT"]       =  {2, 20, 1},
  ["LEN"]      =  {2, 21, 1},  ["CONCAT"]    =  {3, 22, 3},  ["JMP"]      =  {1, 23, 4}, ["EQ"]        =  {3, 24, 3},
  ["LT"]       =  {3, 25, 3},  ["LE"]        =  {3, 26, 3},  ["TEST"]     =  {2, 27, 1}, ["TESTSET"]   =  {3, 28, 3},
  ["CALL"]     =  {3, 29, 3},  ["TAILCALL"]  =  {3, 30, 3},  ["RETURN"]   =  {2, 31, 1}, ["FORLOOP"]   =  {2, 32, 5},
  ["FORPREP"]  =  {2, 33, 5},  ["TFORLOOP"]  =  {2, 34, 1},  ["SETLIST"]  =  {3, 35, 3}, ["CLOSE"]     =  {1, 36, 0},
  ["CLOSURE"]  =  {2, 37, 5},  ["VARARG"]    =  {2, 38, 1},  ["DEBUG"]    =  {1, 39, 0}
}

-- OPCODE := (Instruction & ~((~0) << 6))
function OPCodes.GET_OPCODE(Instruction)
  return Instruction % 64
end

-- ARG_A := ((Instruction >> 6) & ~((~0) << 8))
function OPCodes.GETARG_A(Instruction)
  return Floor(Instruction / 64) % 256
end

-- ARG_B := ((Instruction >> 23) & ~((~0) << 9))
function OPCodes.GETARG_B(Instruction)
  return Floor(Instruction / 8388608) % 512
end

-- ARG_C := ((Instruction >> 14) & ~((~0) << 9))
function OPCodes.GETARG_C(Instruction)
  local Result = Floor(Instruction / 16384) % 512
  return Result
end

-- ARG_Bx := ((Instruction >> 14) & ~((~0) << 18))
function OPCodes.GETARG_Bx(Instruction)
  return Floor(Instruction / 16384) % 262144
end

-- ARG_sBx := (ARG_Bx - MAXARG_sBx)
function OPCodes.GETARG_sBx(Instruction)
  return (Instruction % 65536) - 32768
end

function OPCodes.ReadInstruction(Instruction)
  local OPIndex = OPCodes.GET_OPCODE(Instruction)
  
  local OPName = OPCodes.OP_ENUM[OPIndex + 1]
  local OPTable = OPCodes.OP_Table[OPName]
  local ParamMode = OPTable[3]
  
  local A, B, C
  if ParamMode == 0 then
    A = OPCodes.GETARG_A(Instruction)
  elseif ParamMode == 1 then
    A, B = OPCodes.GETARG_A(Instruction), OPCodes.GETARG_B(Instruction)
  elseif ParamMode == 2 then
    A, B = OPCodes.GETARG_A(Instruction), OPCodes.GETARG_Bx(Instruction)
  elseif ParamMode == 3 then
    A, B, C = OPCodes.GETARG_A(Instruction), OPCodes.GETARG_B(Instruction), OPCodes.GETARG_C(Instruction)
  elseif ParamMode == 4 then
    A = OPCodes.GETARG_sBx(Instruction)
  elseif ParamMode == 5 then
    A, B = OPCodes.GETARG_A(Instruction), OPCodes.GETARG_sBx(Instruction)
  end

  return OPName, A, B, C
end

function OPCodes.ReadFunction(Contents)
  local PC = 12
  local function Range(Start, End, Convert)
    PC = PC + Start
    local ConcatTb = {}
    for Index = Start, End do
      Insert(ConcatTb, (Convert and Contents[PC]) or Contents[PC]:byte())
      PC = PC + 1
    end
    return (Convert and Concat(ConcatTb, "")) or ConcatTb
  end
  local FunctionInfo = {}

  FunctionInfo.NameLength = Range(1, 1)
  FunctionInfo.Name = Range(7, 7 + FunctionInfo["NameLength"][1] - 1, true)
  FunctionInfo.Info = Range(10, 14)
  FunctionInfo.Instructions = Range(1, FunctionInfo.Info[3] * 4)
  FunctionInfo.Constants = Range(1, 30)

  return FunctionInfo
end

function OPCodes.ReadHeader(Contents)
  local function Range(Start, End, Convert)
    local ConcatTb = {}
    for Index = Start, End do
      Insert(ConcatTb, (Convert and Contents[Index]) or Contents[Index]:byte())
    end
    return (Convert and Concat(ConcatTb, "")) or ConcatTb
  end
  local HeaderInfo = {}

  HeaderInfo.Signature = Range(1, 4)
  HeaderInfo.Version = Range(5,5)
  HeaderInfo.Format = Range(6, 6)
  HeaderInfo.Endianess = Range(7,7)
  HeaderInfo.IntSize = Range(8,8)
  HeaderInfo.WordSize = Range(9,9)
  HeaderInfo.InstructionSize = Range(10, 10)
  HeaderInfo.LuaNumberSize = Range(11, 11)
  HeaderInfo.LuaNumberIntegral = Range(12, 12)

  return HeaderInfo
end

function OPCodes.ReadFile(FilePath)
  -- Open binary file
  local FileFD = io.open(FilePath)
  local Contents = FileFD:read("*a")
  FileFD:close()

  Contents = Helpers.StringToTable(Contents)
  local HeaderInfo = OPCodes.ReadHeader(Contents)
  local FunctionInfo = OPCodes.ReadFunction(Contents, StartIndex)
  local BinaryInstructions = FunctionInfo.Instructions
  
  local Instructions = {}
  local Constants = {}

  for Index = 1, #BinaryInstructions, 4 do
    local CurrentInstruction = ""

    -- Read it from right to left, because it's low-endian
    for Index2 = Index + 3, Index, -1 do
      local HexNumber = ToHex(BinaryInstructions[Index2])
      if #HexNumber < 2 then HexNumber = "0"..HexNumber end
      CurrentInstruction = CurrentInstruction .. HexNumber
    end
    print(CurrentInstruction)
    CurrentInstruction = tonumber(CurrentInstruction, 16)
    
    table.insert(Instructions, {OPCodes.ReadInstruction(CurrentInstruction)})
  end

  for Index, Value in pairs(FunctionInfo.Constants) do

  end

  return Instructions, Constants
end

return OPCodes