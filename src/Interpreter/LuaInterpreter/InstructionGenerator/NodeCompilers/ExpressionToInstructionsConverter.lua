--[[
  Name: ExpressionToInstructionsConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module stores the functions for
    converting AST expression nodes to instructions.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/ExpressionToInstructionsConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local find = table.find or Helpers.TableFind
local insert = table.insert
local unpack = (unpack or table.unpack)

--* ExpressionToInstructionsConverter *--
local ExpressionToInstructionsConverter = {}

-----------------// Literal and Identifier Nodes \\-----------------

-- Constant: { Value: "" }
function ExpressionToInstructionsConverter:Constant(node)
  local constantValue = tostring(node.Value)
  local constantRegister = self:allocateRegister()

  if tostring(constantValue) == "nil" then
    -- OP_LOADNIL [A, B]    R(A) := ... := R(B) := nil
    self:addInstruction("LOADNIL", constantRegister, constantRegister)
    return constantRegister
  end
  -- It's a boolean
  
  local booleanNumber = (constantValue == "true" and 1) or 0

  -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
  self:addInstruction("LOADBOOL", constantRegister, booleanNumber, 0)
  return constantRegister
end

-- Identifier: { Value: "" }
function ExpressionToInstructionsConverter:Identifier(node)
  local variableName = node.Value
  
  local localRegister = self:getLocalRegister(variableName)
  if not localRegister then
    -- It's not a local variable, so it must be a global variable
    local globalRegister = self:allocateRegister()
    local constantIndex = self:findOrAddConstant(variableName)
    
    -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
    self:addInstruction("GETGLOBAL", globalRegister, constantIndex)
    return globalRegister
  end

  -- It's a local variable
  return localRegister
end

-- Number: { Value: "" }
function ExpressionToInstructionsConverter:Number(node)
  local numberValue = node.Value
  local constantIndex = self:findOrAddConstant(numberValue)
  local constantRegister = self:allocateRegister()
  
  -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
  self:addInstruction("LOADK", constantRegister, constantIndex)
  return constantRegister
end

-- String: { Value: "" }
function ExpressionToInstructionsConverter:String(node)
  local stringValue = node.Value
  local constantIndex = self:findOrAddConstant(stringValue)
  local constantRegister = self:allocateRegister()
  
  -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
  self:addInstruction("LOADK", constantRegister, constantIndex)
  return constantRegister
end

-- Table: { Elements: {} }
function ExpressionToInstructionsConverter:Table(node)
  local elements = node.Elements

  local tableRegister = self:allocateRegister()
  
  -- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
  self:addInstruction("NEWTABLE", tableRegister, 0, 0)
  
  -- Elements: { { Key: "", Value: "" } } 
  for _, element in ipairs(elements) do
    local value = element.Value
    local key = element.Key 
    
    local valueRegister = self:processExpressionNode(value)
    local keyRegister = self:processExpressionNode(key)

    -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
    self:addInstruction("SETTABLE", tableRegister, keyRegister, valueRegister)

    -- Free the registers
    self:deallocateRegisters({ valueRegister, keyRegister })

  end
  
  return tableRegister
end

-----------------// Table Indexing \\-----------------

-- Index: { Expression: {}, Index: {} }
function ExpressionToInstructionsConverter:Index(node)
  local expression = node.Expression
  local index = node.Index

  local fieldRegister = self:allocateRegister()
  local expressionRegister = self:processExpressionNode(expression)
  local indexRegister = self:processExpressionNode(index)

  -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
  self:addInstruction("GETTABLE", fieldRegister, expressionRegister, indexRegister)

  -- Free the registers
  self:deallocateRegisters({ expressionRegister, indexRegister })

  return fieldRegister
end

-- MethodIndex: { Expression: {}, Index: {} }
function ExpressionToInstructionsConverter:MethodIndex(node)
  local expression = node.Expression
  local index = node.Index

  local fieldRegister = self:allocateRegister()
  local expressionRegister = self:processExpressionNode(expression)
  local indexRegister = self:processExpressionNode(index)

  -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
  self:addInstruction("GETTABLE", fieldRegister, expressionRegister, indexRegister)

  -- Free the registers
  self:deallocateRegisters({ expressionRegister, indexRegister })

  return fieldRegister
end

-----------------// Operators \\-----------------

-- Operator: { Left: {}, Right: {}, Value: "" }
function ExpressionToInstructionsConverter:Operator(node)
  local left = node.Left
  local right = node.Right
  local value = node.Value

  local resultRegister = self:allocateRegister()

  local arithmeticOperators = {
    ["+"] = "ADD",  -- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
    ["-"] = "SUB",  -- OP_SUB [A, B, C]    R(A) := RK(B) - RK(C)
    ["*"] = "MUL",  -- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
    ["/"] = "DIV",  -- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
    ["%"] = "MOD",  -- OP_MOD [A, B, C]    R(A) := RK(B) % RK(C)
    ["^"] = "POW",  -- OP_POW [A, B, C]    R(A) := RK(B) ^ RK(C)
  }

  -- Check if it's an arithmetic operator first, since they're the most common operators.
  if arithmeticOperators[value] then
    local leftRegister = self:processExpressionNode(left)
    local rightRegister = self:processExpressionNode(right)

    self:addInstruction(arithmeticOperators[value], resultRegister, leftRegister, rightRegister)
    return resultRegister
  end

  return error("Operator not supported: " .. value)
end

-- UnaryOperator: { Operand: {}, Value: "" }
function ExpressionToInstructionsConverter:UnaryOperator(node)
  local operand = node.Operand
  local value = node.Value

  local unaryOperators = {
    ["not"] = "NOT",  -- OP_NOT [A, B]    R(A) := not R(B)
    ["-"]   = "UNM",  -- OP_UNM [A, B]    R(A) := -R(B)
    ["#"]   = "LEN",  -- OP_LEN [A, B]    R(A) := length of R(B)
  }

  local unaryOperatorOP = unaryOperators[value]
  if not unaryOperatorOP then
    return error("Unary operator not supported: " .. value)
  end

  local resultRegister = self:allocateRegister()
  local operandRegister = self:processExpressionNode(operand)

  self:addInstruction(unaryOperatorOP, resultRegister, operandRegister)
  return resultRegister
end

-----------------// Function calls \\-----------------

-- FunctionCall: { Expression: {}, Arguments: {} }
function ExpressionToInstructionsConverter:FunctionCall(node)
  local expression = node.Expression
  local arguments = node.Arguments

  local expressionRegister = self:processExpressionNode(expression)

  local argumentRegisters = {}
  for index, argument in ipairs(arguments) do
    local argumentRegister = self:processExpressionNode(argument)
    -- If the arguments are not consecutive, move them to consecutive registers
    -- This mostly happens if there's a leak from the previous expression
    -- or a local variable (the contents of which are stored only once constantly, so it has
    -- a constant register, with multiple temporary registers)
    if argumentRegister ~= (expressionRegister + index) then
      -- OP_MOVE [A, B]    R(A) := R(B)
      self:addInstruction("MOVE", expressionRegister + index, argumentRegister)
    end
    insert(argumentRegisters, argumentRegister)
  end

  local functionCallRegisters = {expressionRegister, unpack(argumentRegisters)}
  
  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  self:addInstruction("CALL", expressionRegister, #arguments + 1, 1)
  self:deallocateRegisters(functionCallRegisters)

  return -666
end

return ExpressionToInstructionsConverter