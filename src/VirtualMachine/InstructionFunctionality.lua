--[[
  Name: InstructionFunctionality.lua
  Author: ByteXenon [Luna Gilbert] & Evan L. P.
  Date: 2024-05-14
  Description:
    This module provides functionality for executing Lua instructions. It defines
    functions for each Lua instruction, such as arithmetic operations, logical
    operations, and control flow instructions. These functions manipulate the
    state of a Lua virtual machine, including its registers, constants, and
    upvalues.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Proto = require("Structures/Proto")
local Closure = require("Structures/Closure")

--* Imports *--
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* Local functions *--
local function returnFromClosure(self, returnTb)
  self.pc = -1
end

--* InstructionFunctionality *--
local InstructionFunctionality = {}

-- OP_MOVE [A, B]    R(A) := R(B)
-- Copy a value between registers
function InstructionFunctionality:MOVE(A, B)
  local register = self.register

  register[A] = register[B]
end

-- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
-- Load a constant into a register
function InstructionFunctionality:LOADK(A, B)
  local register = self.register
  local constants = self.constants

  register[A] = constants[-B]
end

-- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B if (C) pc++
-- Load a boolean into a register
function InstructionFunctionality:LOADBOOL(A, B, C)
  local register = self.register

  register[A] = (B == 1)
  if C and C ~= 0 then
    self.pc = self.pc + 1
  end
end

-- OP_LOADNIL [A, B]    R(A) := ... := R(B) := nil
-- Load nil values into a range of registers
function InstructionFunctionality:LOADNIL(A, B)
  local register = self.register

  for index = A, B do
    register[index] = nil
  end
end

-- OP_GETUPVAL [A, B]    R(A) := UpValue[B]
-- Read an upvalue into a register
function InstructionFunctionality:GETUPVAL(A, B)
  local register = self.register

  register[A] = self.upvalues[B + 1].register[self.upvalues[B + 1].index]
end

-- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
-- Load a global into a register
function InstructionFunctionality:GETGLOBAL(A, B)
  local register = self.register
  local constants = self.constants

  register[A] = self.env[constants[-B]]
end

-- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
-- Read a table element into a register
function InstructionFunctionality:GETTABLE(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = register[B][constants[-C] or register[C]]
end

-- OP_SETGLOBAL [A, Bx]    Gbl[Kst(Bx)] := R(A)
-- Write a register value into a global
function InstructionFunctionality:SETGLOBAL(A, Bx)
  local register = self.register
  local constants = self.constants

  self.env[constants[-Bx]] = register[A]
end

-- OP_SETUPVAL [A, B]    UpValue[B] := R(A)
-- Write a register value into an upvalue
function InstructionFunctionality:SETUPVAL(A, B)
  local register = self.register

  self.upvalues[B + 1].register[self.upvalues[B + 1].index] = register[A]
end

-- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
-- Write a register value into a table element
function InstructionFunctionality:SETTABLE(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A][constants[-B] or register[B]] = (constants[-C] or register[C])
end

-- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
-- Create a new table
function InstructionFunctionality:NEWTABLE(A, B, C)
  local register = self.register

  register[A] = {}
end

-- OP_SELF [A, B, C]    R(A+1) := R(B) R(A) := R(B)[RK(C)]
-- Prepare an object method for calling
function InstructionFunctionality:SELF(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A + 1] = register[B]
  register[A] = register[B][constants[-C] or register[C]]
end

-- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
-- Addition operator
function InstructionFunctionality:ADD(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) + (constants[-C] or register[C])
end

-- OP_SUB [A, B, C]    R(A) := RK(B) - RK(C)
-- Subtraction operator
function InstructionFunctionality:SUB(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) - (constants[-C] or register[C])
end

-- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
-- Multiplication operator
function InstructionFunctionality:MUL(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) * (constants[-C] or register[C])
end

-- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
-- Division operator
function InstructionFunctionality:DIV(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) / (constants[-C] or register[C])
end

-- OP_MOD [A, B, C]    R(A) := RK(B) % RK(C)
-- Modulus (remainder) operator
function InstructionFunctionality:MOD(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) % (constants[-C] or register[C])
end

-- OP_POW [A, B, C]    R(A) := RK(B) ^ RK(C)
-- Exponentation operator
function InstructionFunctionality:POW(A, B, C)
  local register = self.register
  local constants = self.constants

  register[A] = (constants[-B] or register[B]) ^ (constants[-C] or register[C])
end

-- OP_UNM [A, B]    R(A) := -R(B)
-- Unary minus
function InstructionFunctionality:UNM(A, B, C)
  local register = self.register

  register[A] = -register[B]
end

-- OP_NOT [A, B]    R(A) := not R(B)
-- Logical NOT operator
function InstructionFunctionality:NOT(A, B, C)
  local register = self.register
  register[A] = not register[B]
end

-- OP_LEN [A, B]    R(A) := length of R(B)
-- Length operator
function InstructionFunctionality:LEN(A, B, C)
  local register = self.register
  register[A] = #register[B]
end

-- OP_CONCAT [A, B, C]    R(A) := R(B).. ... ..R(C)
-- Concatenate a range of registers
function InstructionFunctionality:CONCAT(A, B, C)
  local register = self.register
  local stringTb = {}
  -- Initialize a custom counter, because we
  -- need to make it's as fast as possible
  local counter = 1
  for i = B, C do
    stringTb[counter] = register[i]
    counter = counter + 1
  end
  register[A] = concat(stringTb)
end

-- OP_JMP [A, sBx]    pc+=sBx
-- Unconditional jump
function InstructionFunctionality:JMP(A, sBx)
  self.pc = self.pc + sBx
end

-- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++
-- Equality test, with conditional jump
function InstructionFunctionality:EQ(A, B, C)
  local register = self.register
  local constants = self.constants
  local RK_B = constants[-B] or register[B]
  local RK_C = constants[-C] or register[C]

  if (RK_B == RK_C) ~= (A == 1) then
    self.pc = self.pc + 1
  end
end

-- OP_LT [A, B, C]    if ((RK(B) <  RK(C)) ~= A) then pc++
-- Less than test, with conditional jump
function InstructionFunctionality:LT(A, B, C)
  local register = self.register
  local constants = self.constants
  local RK_B = constants[-B] or register[B]
  local RK_C = constants[-C] or register[C]

  if ( RK_B < RK_C ) ~= (A == 1) then
    self.pc = self.pc + 1
  end
end

-- OP_LE [A, B, C]    if ((RK(B) <= RK(C)) ~= A) then pc++
-- Less than or equal to test, with conditional jump
function InstructionFunctionality:LE(A, B, C)
  local register = self.register
  local constants = self.constants
  local RK_B = constants[-B] or register[B]
  local RK_C = constants[-C] or register[C]

  if ( RK_B <= RK_C ) ~= (A == 1) then
    self.pc = self.pc + 1
  end
end

-- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
-- Boolean test, with conditional jump
function InstructionFunctionality:TEST(A, B, C)
  local B = C or B -- For future compabillity.
  if (not self.register[A]) == (B == 1) then
    self.pc = self.pc + 1
  end
end

-- OP_TESTSET [A, B, C]    if (R(B) <=> C) then R(A) := R(B) else pc++
-- Boolean test, with conditional jump and assignment
function InstructionFunctionality:TESTSET(A, B, C)
  local register = self.register

  if (not not register[B]) == (C == 1) then
    register[A] = register[B]
  else
    self.pc = self.pc + 1
  end
end

-- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
-- Call a closure
function InstructionFunctionality:CALL(A, B, C)
  local register = self.register
  local closureToCall = register
  local arguments = {}

  if B == 0 then
    B = #register - A + 2
  end

  local index = 1
  for i = A + 1, A + B - 1 do
    arguments[index] = register[i]
    index = index + 1
  end
  local results = { register[A](unpack(arguments)) }

  local index = 1
  for i = A, A + C - 2 do
    register[i] = results[index]
    index = index + 1
  end
end

-- OP_TAILCALL [A, B, C]    return R(A)(R(A+1), ... ,R(A+B-1))
-- Perform a tail call
function InstructionFunctionality:TAILCALL(A, B, C)
  local register = self.register

  local arguments = {}
  local index = 1
  for i = A + 1, A + B - 1 do
    arguments[index] = register[i]
    index = index + 1
  end

  returnFromClosure({register[A](unpack(arguments))})
end

-- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
-- Return from function call
function InstructionFunctionality:RETURN(A, B)
  local register = self.register

  local table1 = {}
  local index = 1
  for i = A, A + B - 2 do
    table1[index] = register[i]
    index = index + 1
  end

  returnFromClosure(table1)
end

-- OP_FORLOOP [,A sBx]   R(A)+=R(A+2)
--                       if R(A) <?= R(A+1) then { pc+=sBx R(A+3)=R(A) }
-- Iterate a numeric for loop
function InstructionFunctionality:FORLOOP(A, B)
  local register = self.register

  -- HACK: Optimized for performance
  local _ = register[A] + register[A + 2]
  if _ <= register[A + 1] then
    self.pc = self.pc + B
    register[A + 3] = _
  end
  register[A] = _
end

-- OP_FORPREP [A, sBx]    R(A)-=R(A+2) pc+=sBx
-- Initialization for a numeric for loop
function InstructionFunctionality:FORPREP(A, B)
  local register = self.register

  register[A] = register[A] - register[A + 2]
  self.pc = self.pc + B
end

-- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2))
--                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
-- Iterate a generic for loop
function InstructionFunctionality:TFORLOOP(A, B, C)
  local register = self.register

  local C = C or B
  local table1 = {register[A](register[A + 1], register[A + 2])}
  local index = 1
  for i = A + 3, A + 2 + C do
    register[i] = table1[index]
    index = index + 1
  end
  if register[A + 3] ~= nil then
    register[A + 2] = register[A + 3]
  else
    self.pc = self.pc + 1
  end
end

-- OP_SETLIST [A, B, C]    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
-- Set a range of array elements for a table
function InstructionFunctionality:SETLIST(A, B, C)
  local register = self.register

  local table = register[A]
  local index = 1
  for i = A + 1, A + B + 1, C do
    table[index] = register[i]
    index = index + 1
  end
end

-- OP_CLOSE [A]
-- close( R(0), ..., R(A) )
-- close all variables in the stack up to (>=) R(A)
function InstructionFunctionality:CLOSE(A)
  local register = self.register

  for i = 0, A do
    register[i] = nil
  end
end

-- OP_CLOSURE [A, Bx]
-- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
-- Create a closure of a function prototype
function InstructionFunctionality:CLOSURE(A, B)
  local register = self.register
  local protos = self.protos

  local proto = protos[B]
  local newClosure = Closure:new()
  newClosure.proto = proto
  newClosure.func = function(...)
    -- Setup upvalues
    proto.upvalues = newClosure.upvalues
    return self:runProto(proto)
  end
  newClosure.upvalues = {}
  if proto.numUpvalues > 0 then
    for upvalueName, upvalueRegister in pairs(proto.upvalues) do
      -- Since lua doesn't have pointers/references, we need to create a new table for each upvalue
      -- and hold the current register as a value in the table
      newClosure.upvalues[#newClosure.upvalues + 1] = {
        register = register,
        index = upvalueRegister,
        name = upvalueName
      }
    end
  end

  -- Skip the upvalues' assignment instructions
  self.pc = self.pc + (proto.numUpvalues or 0)

  register[A] = newClosure.func
end

-- OP_VARARG [A, B]
-- R(A), R(A+1), ..., R(A+B-1) = vararg
-- Assign vararg function arguments to registers
function InstructionFunctionality:VARARG(A, B)
  local register = self.register
  local vararg = self.vararg

  local varargIndex = 1
  for i = A, A + B - 1 do
    register[i] = vararg[varargIndex]
    varargIndex = varargIndex + 1
  end
end

return InstructionFunctionality