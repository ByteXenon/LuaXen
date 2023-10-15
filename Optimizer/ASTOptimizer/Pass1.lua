--[[
  Name: Pass1.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

-- Pass1: Simple optimizations

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/Pass1")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local function addASTNumber(number) return { TYPE = "Number", Value = number } end
local function addASTString(str) return { TYPE = "String", Value = str } end
local function addASTConstant(value) return { TYPE = "Constant", Value = value } end
local function addASTFunctionCall(expression, arguments)
  return { TYPE = "FunctionCall", Expression = expression, Arguments = arguments}
end
local function addASTOperator(value, left, right)
  return { TYPE = "Operator", Value = value, Left = left, Right = right }
end
local function addASTUnaryOperator(value, operand)
  return { TYPE = "UnaryOperator", Operand = operand }
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
      return addASTUnaryOperator(value, evaluatedOperand)
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

--* Pass1 *--
local Pass1 = {}
function Pass1:new(astHierarchy)
  local Pass1Instance = {}
  Pass1Instance.ast = astHierarchy

  function Pass1Instance:foldConstants()
    local expressions = self.ast:getDescendantsWithType("Expression")
    for _, expression in pairs(expressions) do
      expression.Value = compileTimeEvaluateExpression(expression.Value)
    end
  end
  function Pass1Instance:run()
    self:foldConstants()
    return self.ast
  end
  
  return Pass1Instance
end

return Pass1