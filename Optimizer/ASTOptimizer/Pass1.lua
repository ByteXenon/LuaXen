--[[
  Name: Pass1.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

-- Pass1: Simple optimizations

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/Pass1")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeMethods = ModuleManager:loadModule("ASTHierarchy/NodeMethods/NodeMethods")

local function applyMethods(node)
  local nodeType = node.TYPE
  for index, method in pairs(NodeMethods[nodeType]) do
    node[index] = function(self, ...)
      return method(self, node, ...)
    end
  end
  return node
end

local function addASTNumber(number)
  return applyMethods{ TYPE = "Number", Value = number }
end
local function addASTString(str)
  return applyMethods{ TYPE = "String", Value = str }
end
local function addASTConstant(value)
  return applyMethods{ TYPE = "Constant", Value = value }
end
local function addASTFunctionCall(expression, arguments)
  return applyMethods{ TYPE = "FunctionCall", Expression = expression, Arguments = arguments}
end
local function addASTOperator(value, left, right)
  return applyMethods{ TYPE = "Operator", Value = value, Left = left, Right = right }
end
local function addASTUnaryOperator(value, operand)
  return applyMethods{ TYPE = "UnaryOperator", Operand = operand }
end

local function compileTimeEvaluateExpression(node)
  local function isANumber(left, right) return (left and left.TYPE == "Number") and (not right or isANumber(right)) end
  local function isAConstant(left, right) return (left and left.TYPE == "Constant") and (not right or isAConstant(right)) end
  local function isANumberOrAConstant(left, right)
    return (left and (isANumber(left) or isAConstant(left))) and (not right or isANumberOrAConstant(right))
  end

  local type = node.TYPE
  if type == "Operator" then
    local value = node.Value
    local left = node.Left
    local right = node.Right
    
    local evaluatedLeft = compileTimeEvaluateExpression(left)
    local evaluatedRight = compileTimeEvaluateExpression(right)
 
    if (evaluatedLeft.TYPE == "String" or evaluatedLeft.TYPE == "Number")
     and (evaluatedRight.TYPE == "String" or evaluatedRight.TYPE == "Number") then
      if value == ".." then
        return addASTString(evaluatedLeft.Value .. evaluatedRight.Value)
      end
    end

    if not isANumberOrAConstant(evaluatedLeft, evaluatedRight) then
      return addASTOperator(value, evaluatedLeft, evaluatedRight)
    end

    if value == "==" then
      local result = (evaluatedLeft.Value == evaluatedRight.Value)
      if not result or result == true then return addASTConstant(result) end
    elseif value == "and" then
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
    
    if     value == "+"  then return addASTNumber  (evaluatedLeft.Value +  evaluatedRight.Value)
    elseif value == "-"  then return addASTNumber  (evaluatedLeft.Value -  evaluatedRight.Value)
    elseif value == "/"  then return addASTNumber  (evaluatedLeft.Value /  evaluatedRight.Value)
    elseif value == "*"  then return addASTNumber  (evaluatedLeft.Value *  evaluatedRight.Value)
    elseif value == "^"  then return addASTNumber  (evaluatedLeft.Value ^  evaluatedRight.Value)
    elseif value == "%"  then return addASTNumber  (evaluatedLeft.Value %  evaluatedRight.Value)
    elseif value == ">"  then return addASTConstant(evaluatedLeft.Value >  evaluatedRight.Value)
    elseif value == "<"  then return addASTConstant(evaluatedLeft.Value <  evaluatedRight.Value)
    elseif value == ">=" then return addASTConstant(evaluatedLeft.Value >= evaluatedRight.Value)
    elseif value == "<=" then return addASTConstant(evaluatedLeft.Value <= evaluatedRight.Value)
    end
  elseif type == "FunctionCall" then
    local arguments = node.Arguments
    local functionExpression = node.Expression
    for index, argument in ipairs(arguments) do
      arguments[index] = compileTimeEvaluateExpression(argument)
    end
    local evaluatedFunctionExpression = compileTimeEvaluateExpression(functionExpression)
    return addASTFunctionCall(evaluatedFunctionExpression, arguments)
  end

  return node
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