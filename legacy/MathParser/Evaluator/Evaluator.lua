--[[
  Name: Evaluator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Imports *--
local unpack = (unpack or table.unpack)
local insert = table.insert

--* Constants *--
local DEFAULT_OPERATOR_FUNCTIONS = {
  Unary = {
    ["-"] = function(operandValue) return -operandValue end
  },
  Binary = {
    ["+"] = function(leftValue, rightValue) return leftValue + rightValue end,
    ["-"] = function(leftValue, rightValue) return leftValue - rightValue end,
    ["/"] = function(leftValue, rightValue) return leftValue / rightValue end,
    ["*"] = function(leftValue, rightValue) return leftValue * rightValue end,
    ["^"] = function(leftValue, rightValue) return leftValue ^ rightValue end,
    ["%"] = function(leftValue, rightValue) return leftValue % rightValue end
  }
}

local DEFAULT_FUNCTIONS = {
  sin   = math.sin,   cos   = math.cos,
  tan   = math.tan,   asin  = math.asin,
  acos  = math.acos,  atan  = math.atan,
  floor = math.floor, ceil  = math.ceil,
  abs   = math.abs,   sqrt  = math.sqrt,
  log   = math.log,   log10 = math.log10,
  exp   = math.exp,   rad   = math.rad,
  deg   = math.deg
}

--* EvaluatorMethods *--
local EvaluatorMethods = {}

--// PRIVATE METHODS \\--

--- Evaluates the given unary operator node.
-- @param <Table> node The node to evaluate.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluateUnaryOperator(node)
  local nodeValue = node.Value

  local operatorFunction = self.operatorFunctions.Unary[nodeValue]
  assert(operatorFunction, "invalid operator: " .. tostring(nodeValue))

  local operandValue = self:evaluateNode(node.Operand)
  return operatorFunction(operandValue, node)
end

--- Evaluates the given binary operator node.
-- @param <Table> node The node to evaluate.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluateBinaryOperator(node)
  local nodeValue = node.Value
  local nodeLeft = node.Left
  local nodeRight = node.Right

  local operatorFunction = self.operatorFunctions.Binary[nodeValue]
  assert(operatorFunction, "invalid operator")

  local leftValue = self:evaluateNode(nodeLeft)
  local rightValue = self:evaluateNode(nodeRight)
  return operatorFunction(leftValue, rightValue, node)
end

--- Check what type of operator node it is and evaluates it by calling the appropriate function.
-- @param <Table> node The node to evaluate.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluateOperator(node)
  local isUnary = not (not node.Operand)
  if isUnary then
    return self:evaluateUnaryOperator(node)
  end
  return self:evaluateBinaryOperator(node)
end

--- Evaluates a function call node.
-- @param <Table> node The node to evaluate.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluateFunctionCall(node)
  local functionName = node.FunctionName
  local arguments = node.Arguments

  local functionCall = self.functions[functionName] or DEFAULT_FUNCTIONS[functionName]
  assert(functionCall, "invalid function call: " .. tostring(functionName))

  local evaluatedArguments = {}
  for _, argument in ipairs(arguments) do
    local evaluatedArgument = self:evaluateNode(argument)
    insert(evaluatedArguments, evaluatedArgument)
  end

  return functionCall(unpack(evaluatedArguments))
end

--- Evaluates the given node.
-- @param <Table> node The node to evaluate.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluateNode(node)
  local nodeType = node.TYPE

  if nodeType == "Constant" then
    return tonumber(node.Value)
  elseif nodeType == "Variable" then
    if not self.variables[node.Value] then
      return error("Variable not found: " .. tostring(node.Value))
    end
    return self.variables[node.Value]
  elseif nodeType == "Operator" or nodeType == "UnaryOperator" then
    return self:evaluateOperator(node)
  elseif nodeType == "FunctionCall" then
    return self:evaluateFunctionCall(node)
  end

  return error("Invalid node type: " .. tostring(nodeType))
end

--// PUBLIC METHODS \\--

--- Resets the evaluator to its initial state.
-- @param <Table> expression The expression to evaluate.
-- @param <Table?> variables={} The variables to use in the evaluator.
-- @param <Table?> operatorFunctions=DEFAULT_OPERATOR_FUNCTIONS The operator functions to evaluate in the evaluator.
function EvaluatorMethods:resetToInitialState(expression, variables, operatorFunctions, functions)
  assert(expression, "No expression given")

  self.expression = expression
  self.variables = variables or {}
  self.operatorFunctions = operatorFunctions or DEFAULT_OPERATOR_FUNCTIONS
  self.functions = functions or DEFAULT_FUNCTIONS
end

--- Evaluates the given expression.
-- @return <Number> result The result of the evaluation.
function EvaluatorMethods:evaluate()
  assert(self.expression, "No expression to evaluate")

  return self:evaluateNode(self.expression)
end

--* Evaluator *--
local Evaluator = {}

--- @class Creates a new Evaluator instance.
-- @param <Table> expression The expression to evaluate.
-- @param <Table?> variables={} The variables to use in the evaluator.
-- @param <Table?> operatorFunctions=DEFAULT_OPERATOR_FUNCTIONS The operator functions to evaluate in the evaluator.
-- @return <Table> EvaluatorInstance The Evaluator instance.
function Evaluator:new(expression, variables, operatorFunctions, functions)
  local EvaluatorInstance = {}
  EvaluatorInstance.expression = expression
  EvaluatorInstance.variables = variables or {}
  EvaluatorInstance.operatorFunctions = operatorFunctions or DEFAULT_OPERATOR_FUNCTIONS
  EvaluatorInstance.functions = functions or {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if EvaluatorInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and EvaluatorInstance: " .. index)
      end
      EvaluatorInstance[index] = value
    end
  end

  -- Main
  inheritModule("EvaluatorMethods", EvaluatorMethods)

  return EvaluatorInstance
end

return Evaluator