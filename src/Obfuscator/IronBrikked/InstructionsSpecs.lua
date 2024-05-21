--[[
  Name: InstructionsSpecs.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]

--* Constants *--
local MODE_iABC = 0
local MODE_iABx = 1
local MODE_iAsBx = 2
local MODE_iAB = 3

--* InstructionsSpecs *--
local InstructionsSpecs = {}

InstructionsSpecs.OpcodeToNumberLookup = {
  ["MOVE"]     = 0,  ["LOADK"]     = 1,  ["LOADBOOL"] = 2,  ["LOADNIL"]   = 3,
  ["GETUPVAL"] = 4,  ["GETGLOBAL"] = 5,  ["GETTABLE"] = 6,  ["SETGLOBAL"] = 7,
  ["SETUPVAL"] = 8,  ["SETTABLE"]  = 9,  ["NEWTABLE"] = 10, ["SELF"]      = 11,
  ["ADD"]      = 12, ["SUB"]       = 13, ["MUL"]      = 14, ["DIV"]       = 15,
  ["MOD"]      = 16, ["POW"]       = 17, ["UNM"]      = 18, ["NOT"]       = 19,
  ["LEN"]      = 20, ["CONCAT"]    = 21, ["JMP"]      = 22, ["EQ"]        = 23,
  ["LT"]       = 24, ["LE"]        = 25, ["TEST"]     = 26, ["TESTSET"]   = 27,
  ["CALL"]     = 28, ["TAILCALL"]  = 29, ["RETURN"]   = 30, ["FORLOOP"]   = 31,
  ["FORPREP"]  = 32, ["TFORLOOP"]  = 33, ["SETLIST"]  = 34, ["CLOSE"]     = 35,
  ["CLOSURE"]  = 36, ["VARARG"]    = 37,

  -- SUPER INSTRUCTIONS

  -- Different opmodes superinstructions
  ["GETTABLE_AKBKC"] = 38, ["GETTABLE_AKBRC"] = 39, ["GETTABLE_ARBKC"] = 40, ["GETTABLE_ARBRC"] = 41,
  ["SETTABLE_AKBKC"] = 42, ["SETTABLE_AKBRC"] = 43, ["SETTABLE_ARBKC"] = 44, ["SETTABLE_ARBRC"] = 45,
  ["SELF_AKBKC"]     = 46, ["SELF_AKBRC"]     = 47, ["SELF_ARBKC"]     = 48, ["SELF_ARBRC"]     = 49,
  ["ADD_AKBKC"]      = 50, ["ADD_AKBRC"]      = 51, ["ADD_ARBKC"]      = 52, ["ADD_ARBRC"]      = 53,
  ["SUB_AKBKC"]      = 54, ["SUB_AKBRC"]      = 55, ["SUB_ARBKC"]      = 56, ["SUB_ARBRC"]      = 57,
  ["MUL_AKBKC"]      = 58, ["MUL_AKBRC"]      = 59, ["MUL_ARBKC"]      = 60, ["MUL_ARBRC"]      = 61,
  ["DIV_AKBKC"]      = 62, ["DIV_AKBRC"]      = 63, ["DIV_ARBKC"]      = 64, ["DIV_ARBRC"]      = 65,
  ["MOD_AKBKC"]      = 66, ["MOD_AKBRC"]      = 67, ["MOD_ARBKC"]      = 68, ["MOD_ARBRC"]      = 69,
  ["POW_AKBKC"]      = 70, ["POW_AKBRC"]      = 71, ["POW_ARBKC"]      = 72, ["POW_ARBRC"]      = 73,
  ["EQ_AKBKC"]       = 74, ["EQ_AKBRC"]       = 75, ["EQ_ARBKC"]       = 76, ["EQ_ARBRC"]       = 77,
  ["LT_AKBKC"]       = 78, ["LT_AKBRC"]       = 79, ["LT_ARBKC"]       = 80, ["LT_ARBRC"]       = 81,
  ["LE_AKBKC"]       = 82, ["LE_AKBRC"]       = 83, ["LE_ARBKC"]       = 84, ["LE_ARBRC"]       = 85,
}

InstructionsSpecs.SupersetInstructions = {
  ["GETTABLE"] = true,
  ["SETTABLE"] = true,
  ["SELF"] = true,
  ["ADD"] = true,
  ["SUB"] = true,
  ["MUL"] = true,
  ["DIV"] = true,
  ["MOD"] = true,
  ["POW"] = true,
  ["EQ"] = true,
  ["LT"] = true,
  ["LE"] = true
}

InstructionsSpecs.Opmodes = {
  [0] = MODE_iABC,  [1]  = MODE_iABx,  [2]  = MODE_iABC,
  [3] = MODE_iABC,  [4]  = MODE_iABC,  [5]  = MODE_iABx,
  [6] = MODE_iABC,  [7]  = MODE_iABx,  [8]  = MODE_iABC,
  [9] = MODE_iABC,  [10] = MODE_iABC,  [11] = MODE_iABC,
  [12] = MODE_iABC, [13] = MODE_iABC,  [14] = MODE_iABC,
  [15] = MODE_iABC, [16] = MODE_iABC,  [17] = MODE_iABC,
  [18] = MODE_iABC, [19] = MODE_iABC,  [20] = MODE_iABC,
  [21] = MODE_iABC, [22] = MODE_iAsBx, [23] = MODE_iABC,
  [24] = MODE_iABC, [25] = MODE_iABC,  [26] = MODE_iABC,
  [27] = MODE_iABC, [28] = MODE_iABC,  [29] = MODE_iABC,
  [30] = MODE_iABC, [31] = MODE_iAsBx, [32] = MODE_iAsBx,
  [33] = MODE_iABC, [34] = MODE_iABC,  [35] = MODE_iABC,
  [36] = MODE_iABx, [37] = MODE_iABC
}

return InstructionsSpecs