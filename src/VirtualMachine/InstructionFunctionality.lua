--[[
  Name: InstructionFunctionality.lua
  Author: ByteXenon [Luna Gilbert] & Evan L. P.
  Date: 2023-11-XX
  Description:
    This module provides functionality for executing Lua instructions. It defines 
    functions for each Lua instruction, such as arithmetic operations, logical 
    operations, and control flow instructions. These functions manipulate the 
    state of a Lua virtual machine, including its registers, constants, and 
    upvalues.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("VirtualMachine/InstructionFunctionality")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local concat = table.concat
local unpack = (unpack or table.unpack)

--* InstructionFunctionality *--
local InstructionFunctionality = {}
function InstructionFunctionality:new(luaState, VM)
  local InstructionFunctionalityObject = {}

  -- Set these variables as locals, instead of class "self" fields, just
  -- because we need as much performance as possible
  local env = luaState.env
  local register = luaState.register or {}
  local upvalues = luaState.upvalues or {}
  local constants = luaState.constants or {}
  local protos = luaState.protos or {}
  local varArg = luaState.vararg or {}

  -- Require it again here, because otherwise it creates
  -- scary circular dependency errors
  local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")

  local function returnFromClosure(returnValues)
    if VM.stackTrace then
      VM:stopStackTrace()
    end

    -- HACK: make the closure of the virtual machine end without
    --       checking "returnValues" after every instruction by setting the PC to -1
    VM.pc = -1
    VM.returnValues = returnValues
  end

  -- Make a setter for the register
  function InstructionFunctionalityObject:updateRegister(newRegister)
    register = newRegister
  end

  -- OP_MOVE [A, B]    R(A) := R(B)
  -- Copy a value between registers
  function InstructionFunctionalityObject.MOVE(A, B)
    register[A] = register[B]
  end;

  -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
  -- Load a constant into a register
  function InstructionFunctionalityObject.LOADK(A, B)
    register[A] = constants[B]
  end;

  -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
  -- Load a boolean into a register
  function InstructionFunctionalityObject.LOADBOOL(A, B, C)
    register[A] = (B == 1)
    if C and C ~= 0 then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_LOADNIL [A, B]    R(A) := ... := R(B) := nil
  -- Load nil values into a range of registers
  function InstructionFunctionalityObject.LOADNIL(A, B)
    for index = A, B do
      register[index] = nil
    end
  end;

  -- OP_GETUPVAL [A, B]    R(A) := UpValue[B]
  -- Read an upvalue into a register
  function InstructionFunctionalityObject.GETUPVAL(A, B)
    register[A] = upvalues[B]
  end;

  -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
  -- Load a global into a register
  function InstructionFunctionalityObject.GETGLOBAL(A, B)
    register[A] = env[constants[B]]
  end;

  -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
  -- Read a table element into a register
  function InstructionFunctionalityObject.GETTABLE(A, B, C)
    register[A] = register[B][constants[C] or register[C]]
  end;

  -- OP_SETGLOBAL [A, Bx]    Gbl[Kst(Bx)] := R(A)
  -- Write a register value into a global
  function InstructionFunctionalityObject.SETGLOBAL(A, Bx)
    env[constants[A]] = register[Bx]
  end;

  -- OP_SETUPVAL [A, B]    UpValue[B] := R(A)
  -- Write a register value into an upvalue
  function InstructionFunctionalityObject.SETUPVAL(A, B)
    upvalues[A] = register[B]
  end;

  -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
  -- Write a register value into a table element
  function InstructionFunctionalityObject.SETTABLE(A, B, C)
    register[A][constants[B] or register[B]] = (constants[C] or register[C])
  end;

  -- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
  -- Create a new table
  function InstructionFunctionalityObject.NEWTABLE(A, B, C)
    register[A] = {}
  end;

  -- OP_SELF [A, B, C]    R(A+1) := R(B); R(A) := R(B)[RK(C)]
  -- Prepare an object method for calling
  function InstructionFunctionalityObject.SELF(A, B, C)
    register[A + 1] = register[B]
    register[A] = register[B][constants[C] or register[C]]
  end;

  -- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
  -- Addition operator
  function InstructionFunctionalityObject.ADD(A, B, C)
    register[A] = (constants[B] or register[B]) + (constants[C] or register[C])
  end;

  -- OP_SUB [A, B, C]    R(A) := RK(B) - RK(C)
  -- Subtraction operator
  function InstructionFunctionalityObject.SUB(A, B, C)
    register[A] = (constants[B] or register[B]) - (constants[C] or register[C])
  end;

  -- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
  -- Multiplication operator
  function InstructionFunctionalityObject.MUL(A, B, C)
    register[A] = (constants[B] or register[B]) * (constants[C] or register[C])
  end;

  -- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
  -- Division operator
  function InstructionFunctionalityObject.DIV(A, B, C)
    register[A] = (constants[B] or register[B]) / (constants[C] or register[C])
  end;

  -- OP_MOD [A, B, C]    R(A) := RK(B) % RK(C)
  -- Modulus (remainder) operator
  function InstructionFunctionalityObject.MOD(A, B, C)
    register[A] = (constants[B] or register[B]) % (constants[C] or register[C])
  end;

  -- OP_POW [A, B, C]    R(A) := RK(B) ^ RK(C)
  -- Exponentation operator
  function InstructionFunctionalityObject.POW(A, B, C)
    register[A] = (constants[B] or register[B]) ^ (constants[C] or register[C])
  end;

  -- OP_UNM [A, B]    R(A) := -R(B)
  -- Unary minus
  function InstructionFunctionalityObject.UNM(A, B, C)
    register[A] = -register[B]
  end;

  -- OP_NOT [A, B]    R(A) := not R(B)
  -- Logical NOT operator
  function InstructionFunctionalityObject.NOT(A, B, C)
    register[A] = not register[B]
  end;

  -- OP_LEN [A, B]    R(A) := length of R(B)
  -- Length operator
  function InstructionFunctionalityObject.LEN(A, B, C)
    register[A] = #register[B]
  end;

  -- OP_CONCAT [A, B, C]    R(A) := R(B).. ... ..R(C)
  -- Concatenate a range of registers
  function InstructionFunctionalityObject.CONCAT(A, B, C)
    local stringTb = {}
    -- Initialize a custom counter, because we
    -- need to make it's as fast as possible
    local counter = 1
    for i = B, C do
      stringTb[counter] = register[i]
      counter = counter + 1
    end
    register[A] = concat(stringTb)
  end;

  -- OP_JMP [sBx]    pc+=sBx
  -- Unconditional jump
  function InstructionFunctionalityObject.JMP(A)
    VM.pc = VM.pc + A
  end;

  -- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++
  -- Equality test, with conditional jump
  function InstructionFunctionalityObject.EQ(A, B, C)
    local RK_B = constants[B] or register[B]
    local RK_C = constants[C] or register[C]

    if (RK_B == RK_C) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_LT [A, B, C]    if ((RK(B) <  RK(C)) ~= A) then pc++
  -- Less than test, with conditional jump
  function InstructionFunctionalityObject.LT(A, B, C)
    local RK_B = constants[B] or register[B]
    local RK_C = constants[C] or register[C]

    if ( RK_B < RK_C ) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_LE [A, B, C]    if ((RK(B) <= RK(C)) ~= A) then pc++
  -- Less than or equal to test, with conditional jump
  function InstructionFunctionalityObject.LE(A, B, C)
    local RK_B = constants[B] or register[B]
    local RK_C = constants[C] or register[C]

    if ( RK_B <= RK_C ) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
  -- Boolean test, with conditional jump
  function InstructionFunctionalityObject.TEST(A, B, C)
    local B = C or B -- For future compabillity.
    if (not register[A]) == (B == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_TESTSET [A, B, C]    if (R(B) <=> C) then R(A) := R(B) else pc++
  -- Boolean test, with conditional jump and assignment
  function InstructionFunctionalityObject.TESTSET(A, B, C)
    if (not not register[B]) == (C == 1) then
      register[A] = register[B]
    else
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  -- Call a closure
  function InstructionFunctionalityObject.CALL(A, B, C)
    local arguments = {}

    if B == 0 then
      B = #register - A + 2
    end

    local index = 1
    for i = A + 1, A + B - 1 do
      arguments[index] = register[i]
      index = index + 1
    end
    local results = {register[A](unpack(arguments))}

    local index = 1
    for i = A, A + C - 2 do
      register[i] = results[index]
      index = index + 1
    end
  end;

  -- OP_TAILCALL [A, B, C]    return R(A)(R(A+1), ... ,R(A+B-1))
  -- Perform a tail call
  function InstructionFunctionalityObject.TAILCALL(A, B, C)
    local arguments = {}
    local index = 1
    for i = A + 1, A + B - 1 do
      arguments[index] = register[i]
      index = index + 1
    end

    returnFromClosure({register[A](unpack(arguments))})
  end;

  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  -- Return from function call
  function InstructionFunctionalityObject.RETURN(A, B)
    local table1 = {}
    local index = 1
    for i = A, A + B - 2 do
      table1[index] = register[i]
      index = index + 1
    end

    returnFromClosure(table1)
  end;

  -- OP_FORLOOP [A, sBx]   R(A)+=R(A+2);
  --                       if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
  -- Iterate a numeric for loop
  function InstructionFunctionalityObject.FORLOOP(A, B)
    -- HACK: Optimized for performance
    local _ = register[A] + register[A + 2]
    if _ <= register[A + 1] then
      VM.pc = VM.pc + B
      register[A + 3] = _
    end
    register[A] = _
  end;

  -- OP_FORPREP [A, sBx]    R(A)-=R(A+2); pc+=sBx
  -- Initialization for a numeric for loop
  function InstructionFunctionalityObject.FORPREP(A, B)
    register[A] = register[A] - register[A + 2]
    VM.pc = VM.pc + B
  end;

  -- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
  --                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
  -- Iterate a generic for loop
  function InstructionFunctionalityObject.TFORLOOP(A, B, C)
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
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_SETLIST [A, B, C]    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
  -- Set a range of array elements for a table
  function InstructionFunctionalityObject.SETLIST(A, B, C)
    local table = register[A]
    local index = 1
    for i = A + 1, A + B + 1, C do
      table[index] = register[i]
      index = index + 1
    end
  end;

  -- OP_CLOSE [A]
  -- close( R(0), ..., R(A) )
  -- close all variables in the stack up to (>=) R(A)
  function InstructionFunctionalityObject.CLOSE(A)
    for i = 0, A do
      register[i] = nil
    end
  end;

  -- OP_CLOSURE [A, Bx]
  -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
  -- Create a closure of a function prototype
  function InstructionFunctionalityObject.CLOSURE(A, B)
    -- Protos are Lua states
    local proto = protos[B]
    register[A] = function(...)
      return VirtualMachine:new(proto):handler(...)
    end
  end;

  -- OP_VARARG [A, B]
  -- R(A), R(A+1), ..., R(A+B-1) = vararg
  -- Assign vararg function arguments to registers
  function InstructionFunctionalityObject.VARARG(A, B)
    local varArgIndex = 1
    for i = A, A + B - 1 do
      register[i] = varArg[varArgIndex]
      varArgIndex = varArgIndex + 1
    end
  end;

  return InstructionFunctionalityObject
end

return InstructionFunctionality