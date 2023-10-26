--[[
  Name: assembler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Examples/assembler.lua")
local Helpers = require("Helpers/Helpers")

local Assembler = ModuleManager:loadModule("Assembler/Assembler")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")

local state = Assembler:assemble([[
  GETGLOBAL 0, "print"
  LOADK     1, "Hello, world!"
  CALL      0, 2, 1
  RETURN    0, 1
]])

local VMInstance = VirtualMachine:new(state)
return VMInstance:run()