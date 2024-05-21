--[[
  Name: Instructions.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
  Description:
    This module desparately tries to convert Lua VM instructions to Lua code.
    This is needed for obfuscation purposes
--]]

math.randomseed(os.time())

--* Import library functions *--
local insert = table.insert
local concat = table.concat
local floor = math.floor
local random = math.random

--* Local functions *--

-- Helper function to assign a value to a variable
local function assignVariable(variable, value)
  if not variable.IsSet then
    return "local " .. variable.Name .. " = " .. value
  end
  return variable.Name .. " = " .. value
end

-- Helper function to handle RK values
local function handleRKValue(self, B, C)
  local RK_B = self.state.constants[B] or self:registerRegisterVariable(B).Name
  local RK_C = self.state.constants[C] or self:registerRegisterVariable(C).Name
  return RK_B, RK_C
end

-- Helper function to handle arithmetic operations
local function handleArithmeticOperation(self, A, B, C, operation)
  local RK_B, RK_C = handleRKValue(self, B, C)

  local expression
  if type(RK_B) == "number" and type(RK_C) == "number" then
    expression = self:obfuscateNumber(operation(RK_B, RK_C))
  else
    expression = RK_B .. operation .. RK_C
  end

  local variableA = self:registerRegisterVariable(A)
  return assignVariable(variableA, expression)
end

--* Instructions *--
local Instructions = {}

-- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
function Instructions:GETGLOBAL(A, B, C)
  local constant = self.state.constants[B]
  local variable = self:registerRegisterVariable(A)
  return assignVariable(variable, constant)
end

-- OP_CLOSURE [A, Bx]    R(A) := closure(KPROTO[Bx])
function Instructions:CLOSURE(A, B, C)
  local CodePhantom = require("Obfuscator/CodePhantom/CodePhantom")

  local proto = self.state.protos[B] -- Protos are luaStates
  local obfuscatedFunctionString = CodePhantom:new(proto):run()
  return "local function _()\n" .. obfuscatedFunctionString .. "\nend"
end

-- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
function Instructions:LOADK(A, B, C)
  local constant = self.state.constants[B]
  local variable = self:registerRegisterVariable(A)

  if type(constant) == "string" then
    constant = '"' .. constant .. '"'
  elseif type(constant) == "number" then
    constant = self:obfuscateNumber(constant)
  end

  return assignVariable(variable, constant)
end

-- OP_MOVE [A, B]    R(A) := R(B)
function Instructions:MOVE(A, B, C)
  local variableA = self:registerRegisterVariable(A)
  local variableB = self:registerRegisterVariable(B)
  return assignVariable(variableA, variableB.Name)
end

-- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
function Instructions:CALL(A, B, C)
  local args = {}
  for i = A + 1, A + B - 1 do
    insert(args, self:registerRegisterVariable(i).Name)
  end
  return self:registerRegisterVariable(A).Name .. "(" .. concat(args, ",") .. ")"
end

-- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
function Instructions:ADD(A, B, C)
  return handleArithmeticOperation(self, A, B, C, function(a, b) return a + b end)
end

-- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
function Instructions:MUL(A, B, C)
  return handleArithmeticOperation(self, A, B, C, function(a, b) return a * b end)
end

-- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
function Instructions:DIV(A, B, C)
  return handleArithmeticOperation(self, A, B, C, function(a, b) return a / b end)
end

-- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
function Instructions:DIV(A, B, C)
  return handleArithmeticOperation(self, A, B, C, function(a, b) return a % b end)
end


-- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
function Instructions:RETURN(A, B, C)
  local args = {}
  for i = A, A + B - 2 do
    insert(args, self:registerRegisterVariable(i).Name)
  end
  return "return " .. concat(args, ",")
end

return Instructions