--[[
  Name: ExpressionEvaluator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionEvaluator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ScopeState = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ScopeState")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* ExpressionEvaluator *--
local ExpressionEvaluator = {}
function ExpressionEvaluator:new(instructionGenerator)
  local ExpressionEvaluatorInstance = {}

  local function addASTNumber(number) return { TYPE = "Number", Value = number } end
  local function addASTString(str) return { TYPE = "String", Value = str } end
  local function addASTConstant(value) return { TYPE = "Constant", Value = value } end
  local function addASTFunctionCall(expression, arguments)
    return { TYPE = "FunctionCall", Expression = expression, Arguments = arguments}
  end
  local function addASTOperator(value, left, right, operand)
    return { TYPE = "Operator", Value = value, Left = left, Right = right, Operand = operand }
  end

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
  local function compileTimeEvaluateExpression(expression)
    local isANumber;
    local isAConstant;
    local isANumberOrAConstant;
    local function isANumber(left, right) return (left and left.TYPE == "Number") and (not right or isANumber(right)) end
    local function isAConstant(left, right) return (left and left.TYPE == "Constant") and (not right or isAConstant(right)) end
    local function isANumberOrAConstant(left, right)
      return (left and (isANumber(left) or isAConstant(left))) and (not right or isANumberOrAConstant(right))
    end


    local type = expression.TYPE
    if type == "Operator" then
      local value = expression.Value
      local operand = expression.Operand
      if operand then
        local evaluatedOperand = compileTimeEvaluateExpression(operand)
        if value == "#" and (evaluatedOperand.TYPE == "String" or evaluatedOperand.TYPE == "Table") then
          if evaluatedOperand.TYPE == "Table" then
            local elementCount = 0
            for _ in pairs(evaluatedOperand.Values) do
              elementCount = elementCount + 1
            end

            return addASTNumber(elementCount)
          elseif evaluatedOperand.TYPE == "String" then
            return addASTNumber(#evaluatedOperand.Value)
          end
        elseif value == "-" and isANumber(evaluatedOperand) then
          return addASTNumber(-evaluatedOperand.Value)
        end

        -- Unsuported unary operator
        return addASTOperator(value, nil, nil, evaluatedOperand)
      end

      local left = expression.Left
      local right = expression.Right
      local evaluatedLeft = compileTimeEvaluateExpression(left)
      local evaluatedRight = compileTimeEvaluateExpression(right)
   
      if not isANumberOrAConstant(evaluatedLeft, evaluatedRight) then
        return addASTOperator(value, evaluatedLeft, evaluatedRight)
      end

      if value == "and" then
        local result = (evaluatedLeft.Value and evaluatedRight.Value)
        if not result or result == true then return addASTConstant(result) end     
        return addASTNumber(result)
      elseif value == "or" then
        local result = (evaluatedLeft.Value or evaluatedRight.Value)
        if not result or result == true then return addASTConstant(result) end
        return addASTNumber(result)
      end

      if not isANumber(evaluatedLeft, evaluatedRight) then
        return addASTOperator(value, evaluatedLeft, evaluatedRight)
      end
      
      if value == "+" then return addASTNumber(evaluatedLeft.Value + evaluatedRight.Value)
      elseif value == "-" then return addASTNumber(evaluatedLeft.Value - evaluatedRight.Value)
      elseif value == "/" then return addASTNumber(evaluatedLeft.Value / evaluatedRight.Value)
      elseif value == "*" then return addASTNumber(evaluatedLeft.Value * evaluatedRight.Value)
      elseif value == "^" then return addASTNumber(evaluatedLeft.Value ^ evaluatedRight.Value)
      elseif value == "%" then return addASTNumber(evaluatedLeft.Value % evaluatedRight.Value)
      end
    elseif type == "FunctionCall" then
      local arguments = expression.Arguments
      local functionExpression = expression.Expression
      for index, argument in ipairs(arguments) do
        arguments[index] = compileTimeEvaluateExpression(argument)
      end
      local evaluatedFunctionExpression = compileTimeEvaluateExpression(functionExpression)
      return addASTFunctionCall(evaluatedFunctionExpression, arguments)
    end

    return expression
  end

  function ExpressionEvaluatorInstance:evaluateExpressionNode(instructions, expression, canReturnConstantIndex, isStatementContext)
    local expression = compileTimeEvaluateExpression(expression);

    local type = expression.TYPE
    if type == "Operator" then
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
      elseif value == "and" then
        local leftRegister, generatedInstructions1 = self:evaluateExpression(instructions, left)

        -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
        addInstruction(instructions, "TEST", leftRegister, (value == "or" and 1) or 0)
        local jumpInstructionIndex = addInstruction(instructions, "JMP", 1)
        local rightRegister, generatedInstructions2 = self:evaluateExpression(instructions, right)

        changeInstruction(instructions, jumpInstructionIndex, false, jumpInstructionIndex + (#generatedInstructions1 + #generatedInstructions2))
        return rightRegister
      elseif value == "or" then
        local leftRegister = self:evaluateExpression(instructions, left)
        
        -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
        addInstruction(instructions, "TEST", leftRegister, (value == "or" and 1) or 0)
        local jumpInstructionIndex = addInstruction(instructions, "JMP", 1)
        local rightRegister = self:evaluateExpression(instructions, right)
        
        changeInstruction(instructions, jumpInstructionIndex, false, #self.luaState.instructions + jumpInstructionIndex)
        return rightRegister
      elseif value == "==" or value == "~=" then
        local leftRegister = self:evaluateExpression(instructions, left, true)
        local rightRegister = self:evaluateExpression(instructions, right, true)

        local allocatedRegister = self:allocateRegister()
        
        -- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++ 
        addInstruction(instructions, "EQ", (value == "~=" and 0) or 1, leftRegister, rightRegister)
        addInstruction(instructions, "JMP", 1)
        
        -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
        addInstruction(instructions, "LOADBOOL", allocatedRegister, 0, 1)
        addInstruction(instructions, "LOADBOOL", allocatedRegister, 1, 0)
        return allocatedRegister
      end

      local leftRegister = self:evaluateExpression(instructions, left, true)
      local rightRegister = self:evaluateExpression(instructions, right, true)
      local allocatedRegister = self:allocateRegister()
      
      local opName = arithmeticOperators[value]

      addInstruction(instructions, opName, allocatedRegister, leftRegister, rightRegister)
      return allocatedRegister
    elseif type == "Index" then
      local index = expression.Index
      local value = expression.Value
      local valueRegister = self:evaluateExpression(instructions, value)
      local indexConstant = self:evaluateExpression(instructions, index, true)
      if indexConstant >= 0 then self:deallocateRegister(indexConstant) end

      local allocatedRegister = self:allocateRegister()
      
      -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
      addInstruction(instructions, "GETTABLE", allocatedRegister, valueRegister, indexConstant)
      
      return allocatedRegister
    elseif type == "FunctionCall" then
      local arguments = expression.Arguments
      local functionExpression = expression.Expression
      local functionExpressionRegister = self:evaluateExpression(instructions, functionExpression)
      local tempRegisters = {}
      for index, argument in ipairs(arguments) do
        local argumentRegister = self:evaluateExpression(instructions, argument)
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
    elseif type == "Identifier" then
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
    elseif type == "String" or type == "Number" then
      local value = expression.Value
      local constantIndex = self:addConstant(value)
      if canReturnConstantIndex then return constantIndex end

      local allocatedRegister = self:allocateRegister()
      addInstruction(instructions, "LOADK", allocatedRegister, constantIndex)
      return allocatedRegister
    elseif type == "Constant" then
      local value = expression.Value
      local allocatedRegister = self:allocateRegister()
      if value == "nil" then addInstruction(instructions, "LOADNIL",  allocatedRegister, allocatedRegister)
      else
        addInstruction(instructions, "LOADBOOL", allocatedRegister, value == "true" and 1 or 0, 0)
      end
      return allocatedRegister
    end 
  end

  function ExpressionEvaluatorInstance:evaluateExpression(instructions, expression, noInsert)
    local generatedInstructions = {};
    local returnRegister = self:evaluateExpressionNode(generatedInstructions, expression)

    if not noInsert then
      for _, instruction in pairs(generatedInstructions) do
        insert(instructions, instruction)
      end
    end
    return returnRegister, generatedInstructions
  end

  return ExpressionEvaluatorInstance
end

return ExpressionEvaluator