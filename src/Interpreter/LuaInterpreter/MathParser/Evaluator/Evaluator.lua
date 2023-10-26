--[[
  Name: Evaluator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/MathParser/Evaluator/Evaluator")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")

-- * Evaluator * --
local Evaluator = {}
function Evaluator:new(expression, operatorFunctions)
  assert(expression, "Invalid expression: the expression cannot be nil or empty")
  local EvaluatorInstance = {}

  EvaluatorInstance.expression = expression
  EvaluatorInstance.operatorFunctions = operatorFunctions or {
    Unary = {
      ["-"] = function(operandValue) return -operandValue end;
    };
    Binary = {
      ["+"] = function(leftValue, rightValue) return leftValue + rightValue end;
      ["-"] = function(leftValue, rightValue) return leftValue - rightValue end;
      ["/"] = function(leftValue, rightValue) return leftValue / rightValue end;
      ["*"] = function(leftValue, rightValue) return leftValue * rightValue end;
      ["^"] = function(leftValue, rightValue) return leftValue ^ rightValue end;
      ["%"] = function(leftValue, rightValue) return leftValue % rightValue end;
    }
  }

  function EvaluatorInstance:evaluate()
    return self:evaluateNode(self.expression)
  end

  function EvaluatorInstance:evaluateNode(node)
    if node.TYPE == "Constant" then return node.Value
    elseif node.TYPE == "Operator" then
      local isUnary = not not node.Operand;
      if isUnary then
        local operatorFunction = self.operatorFunctions.Unary[node.Value]
        assert(operatorFunction, "invalid operator")

        local operandValue = self:evaluateNode(node.Operand)
        return operatorFunction(operandValue, node)
      end
      local operatorFunction = self.operatorFunctions.Binary[node.Value]
      assert(operatorFunction, "invalid operator")

      local leftValue = self:evaluateNode(node.Left)
      local rightValue = self:evaluateNode(node.Right)
      return operatorFunction(leftValue, rightValue, node)
    else
      return error("Invalid node type: ", tostring(node.TYPE))
    end
  end

  return EvaluatorInstance
end

return Evaluator