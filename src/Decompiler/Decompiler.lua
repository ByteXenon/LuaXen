--[[
  Name: Decompiler.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-08
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaInterpreter = require("Interpreter/LuaInterpreter/LuaInterpreter")

--* Imports *--
local find = Helpers.findTable
local insert = table.insert
local concat = table.concat

--* DecompilerMethods *--
local DecompilerMethods = {}

function DecompilerMethods:getNextName()
  self.nameIndex = self.nameIndex + 1
  return "L_" .. self.nameIndex
end

function DecompilerMethods:registerLocal(register)
  local name = self:getNextName()
  local newLocal = { name = name, register = register }
  self.locals[register] = newLocal
  return name
end

function DecompilerMethods:decompileFunction(proto)
  local instructions = proto.instructions
  -- First pass, get all instructions that belong to OP_CALLs
  -- Go backwards
  local calls = {}
  local index = #instructions
  while index > 0 do
    local instruction = instructions[index]
    local opname = instruction[1]
    if opname == "CALL" then
      local call = { instruction }
      -- Now lets find the preparing instructions
      local argStart = instruction[3] -- The register where arguments start
      local argIndex = index - 1 -- Start from the instruction before the CALL
      while argIndex > 0 do
        local argInstruction = instructions[argIndex]
        local argOpname = argInstruction[1]
        local argRegister = argInstruction[2]
        if argRegister < argStart then
          -- This instruction doesn't prepare an argument for the CALL
          break
        end
        index = index - #call -- Update the index
        -- This instruction prepares an argument for the CALL
        insert(call, 1, argInstruction) -- Add it to the start of the call table
        argIndex = argIndex - 1
      end
      insert(calls, call)
    elseif opname == "CLOSURE" then
      -- Closures have some preparing instructions that never really get executed
      local closure = { instruction }
      local proto = self.protos[instruction[3]]
      local numberOfUpvalues = proto.numUpvalues
      -- Skip
      while numberOfUpvalues > 0 do
        index = index - 1
        insert(closure, 1, instructions[index])
        numberOfUpvalues = numberOfUpvalues - 1
      end
    elseif opname == "FORLOOP" then
      local forloop = { instruction }
      -- Skip
      index = index - 1
      insert(forloop, 1, instructions[index])
      index = index - 1
      insert(forloop, 1, instructions[index])
      insert(calls, forloop)
    end
    index = index - 1
  end

  Helpers.printTable(calls)
  Helpers.printTable(instructions)
end

function DecompilerMethods:decompile()
  return self:decompileFunction(self.proto)
end

--* Decompiler *--
local Decompiler = {}

function Decompiler:new(proto)
  local DecompilerInstance = {}
  DecompilerInstance.proto = proto
  DecompilerInstance.locals = {}
  DecompilerInstance.nameIndex = 0

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if DecompilerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and DecompilerInstance: " .. index)
      end
      DecompilerInstance[index] = value
    end
  end

  -- Main
  inheritModule("DecompilerMethods", DecompilerMethods)

  return DecompilerInstance
end

return Decompiler