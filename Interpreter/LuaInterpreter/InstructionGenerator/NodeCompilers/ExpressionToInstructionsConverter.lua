--[[
  Name: ExpressionToInstructionsConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/ExpressionToInstructionsConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* Local functions *--
local function addInstruction(instructions, opName, a, b, c)
  insert(instructions, { opName, a, b, c })
  return #instructions
end
local function changeInstruction(instructions, instructionIndex, opName, a, b, c)
  local oldInstruction = instructions[instructionIndex]

  instructions[instructionIndex] = {
    (opName == false and oldInstruction[1]) or opName,
    (a == false and oldInstruction[2]) or a,
    (b == false and oldInstruction[3]) or b,
    (c == false and oldInstruction[4]) or c
  }
end


--* ExpressionToInstructionsConverter *--
local ExpressionToInstructionsConverter = {}
function ExpressionToInstructionsConverter:__Expression_Operator(instructions, expression, canReturnConstantIndex, isStatementContext)
  local value = expression.Value
  local left = expression.Left
  local right = expression.Right
  local operand = expression.Operand

  local unaryOperators = {
    ["-"] = "UNM", ["#"] = "LEN"
  }
  local arithmeticOperators = {
    ["+"] = "ADD", ["-"] = "SUB",
    ["^"] = "POW", ["*"] = "MUL",
    ["/"] = "DIV", ["%"] = "MOD",
    [".."] = "CONCAT"
  }

  if operand then
    local operandRegister = self:evaluateExpression(instructions, operand, true)
    local allocatedRegister = self:allocateRegister()

    addInstruction(instructions, unaryOperators[value], allocatedRegister, operandRegister)
    return allocatedRegister
  elseif value == "and" or value == "or" then
    local leftRegister = self:evaluateExpression(instructions, left)

    -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
    addInstruction(instructions, "TEST", leftRegister, (value == "or" and 1) or 0)
    local jumpInstructionIndex = addInstruction(instructions, "JMP", 1)
    self:deallocateRegister(leftRegister)
    local oldInstructionNumber = #instructions
    local rightRegister = self:evaluateExpression(instructions, right)
    local newInstructionNumber = #instructions

    changeInstruction(instructions, jumpInstructionIndex, false, (newInstructionNumber - oldInstructionNumber))
    return rightRegister
  elseif value == "==" or value == "~=" then
    local leftRegister = self:evaluateExpression(instructions, left, true)
    local rightRegister = self:evaluateExpression(instructions, right, true)

    self:deallocateRegisters({ leftRegister, rightRegister })
    local allocatedRegister = self:allocateRegister()

    -- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++
    addInstruction(instructions, "EQ", (value == "==" and 1) or 0, leftRegister, rightRegister)
    addInstruction(instructions, "JMP", 1)

    -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
    addInstruction(instructions, "LOADBOOL", allocatedRegister, 0, 1)
    addInstruction(instructions, "LOADBOOL", allocatedRegister, 1, 0)
    return allocatedRegister
  elseif value == "<" or value == "<=" or value == ">" or value == ">=" then
    local leftRegister = self:evaluateExpression(instructions, left, true)
    local rightRegister = self:evaluateExpression(instructions, right, true)
    if leftRegister >= 0 then self:deallocateRegister(leftRegister) end
    if rightRegister >= 0 then self:deallocateRegister(rightRegister) end

    if value == "<" or value == ">" then
      -- OP_LT [A, B, C]    if ((RK(B) <  RK(C)) ~= A) then pc++
      if value == "<" then
        addInstruction(instructions, "LT", 0, leftRegister, rightRegister)
      elseif value == ">" then
        addInstruction(instructions, "LT", 0, rightRegister, leftRegister)
      end
    elseif value == "<=" or value == ">=" then
      -- OP_LE [A, B, C]    if ((RK(B) <= RK(C)) ~= A) then pc++
      if value == "<=" then
        addInstruction(instructions, "LE", 0, leftRegister, rightRegister)
      elseif value == ">=" then
        addInstruction(instructions, "LE", 0, rightRegister, leftRegister)
      end
    end
    -- Return none because it doens't have a register to return to.
    return
  end

  -- OP_CONCAT is the only operation that doesn't accept constants.
  -- So stupid, but we must follow the official implementation
  local canReturnConstant = (value ~= "..")
  local leftRegister = self:evaluateExpression(instructions, left, canReturnConstant)
  local rightRegister = self:evaluateExpression(instructions, right, canReturnConstant)
  self:deallocateRegisters({ leftRegister, rightRegister })

  local allocatedRegister = self:allocateRegister()

  local opName = arithmeticOperators[value]
  addInstruction(instructions, opName, allocatedRegister, leftRegister, rightRegister)
  return allocatedRegister
end
function ExpressionToInstructionsConverter:__Expression_Index(instructions, expression, canReturnConstantIndex, isStatementContext)
  local index = expression.Index
  local expression = expression.Expression
  local expressionRegister = self:evaluateExpression(instructions, expression)
  local indexConstant = self:evaluateExpression(instructions, index, true)
  -- if indexConstant >= 0 then self:deallocateRegister(indexConstant) end

  self:deallocateRegister(expressionRegister)
  if indexConstant >= 0 then self:deallocateRegister(indexConstant) end
  local allocatedRegister = self:allocateRegister()

  -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
  addInstruction(instructions, "GETTABLE", allocatedRegister, expressionRegister, indexConstant)

  return allocatedRegister
end
function ExpressionToInstructionsConverter:__Expression_Function(instructions, expression, canReturnConstantIndex, isStatementContext)
end
function ExpressionToInstructionsConverter:__Expression_FunctionCall(instructions, expression, canReturnConstantIndex, isStatementContext)
  local arguments = expression.Arguments
  local functionExpression = expression.Expression

  local functionExpressionRegister = self:evaluateExpression(instructions, functionExpression)
  local tempRegisters = {}
  for index, argument in ipairs(arguments) do
    local argumentRegister = self:evaluateExpression(instructions, argument.Value)
    insert(tempRegisters, argumentRegister)
    if argumentRegister ~= functionExpressionRegister + index then
      addInstruction(instructions, "MOVE", functionExpressionRegister + index, argumentRegister)
    end
  end

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  addInstruction(instructions, "CALL", functionExpressionRegister, #arguments + 1, (isStatementContext and 0) or 2)
  if not isStatementContext then
    -- if the function call doesn't return more than 1 value, then deallocate all
    -- argument registers because they're not needed anymore
    self:deallocateRegisters(tempRegisters)
  end

  return functionExpressionRegister
end
function ExpressionToInstructionsConverter:__Expression_Identifier(instructions, expression, canReturnConstantIndex, isStatementContext)
  local value = expression.Value
  -- Check if this is a variable
  local localRegister = self.currentScopeState:findLocal(value)
  if localRegister then
    -- Optimize it. (-1 instruction)
    return localRegister
  end
  local allocatedRegister = self:allocateRegister()
  local constantIndex = self:addConstant(expression.Value)

  addInstruction(instructions, "GETGLOBAL", allocatedRegister, constantIndex)
  return allocatedRegister
end
function ExpressionToInstructionsConverter:__Expression_String(instructions, expression, canReturnConstantIndex, isStatementContext)
  local value = expression.Value
  local constantIndex = self:addConstant(value)
  if canReturnConstantIndex then return constantIndex end

  local allocatedRegister = self:allocateRegister()
  addInstruction(instructions, "LOADK", allocatedRegister, constantIndex)
  return allocatedRegister
end
function ExpressionToInstructionsConverter:__Expression_Number(instructions, expression, canReturnConstantIndex, isStatementContext)
  return self:__Expression_String(instructions, expression, canReturnConstantIndex, isStatementContext)
end
function ExpressionToInstructionsConverter:__Expression_Constant(instructions, expression, canReturnConstantIndex, isStatementContext)
  local value = expression.Value
  local allocatedRegister = self:allocateRegister()
  if value == "nil" then addInstruction(instructions, "LOADNIL",  allocatedRegister, allocatedRegister)
  else
    addInstruction(instructions, "LOADBOOL", allocatedRegister, value == "true" and 1 or 0, 0)
  end
  return allocatedRegister
end

return ExpressionToInstructionsConverter