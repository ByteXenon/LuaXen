--[[
  Name: assembler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--[[
  Notes:
    OP_SELF [A, B, C]    R(A+1) := R(B); R(A) := R(B)[RK(C)]
    OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
    OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Examples/assembler.lua")
local Helpers = require("Helpers/Helpers")

local Assembler = ModuleManager:loadModule("Assembler/Assembler")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")

local state = Assembler:assemble([[
  JMP -1     ; crash the program :]  
  RETURN 0 1 ; return from the function!
]])

state.env["Helpers"] = {
  PrintTable = function(...)
    print("This function was called from the assembler!!!")
    return Helpers.PrintTable(...)
  end
}

local VMInstance = VirtualMachine:new(state)
local r = VMInstance:run()