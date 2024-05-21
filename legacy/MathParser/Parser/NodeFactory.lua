--[[
  Name: NodeFactory.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-01-11
--]]

--* NodeFactory *--
local NodeFactory = {}

function NodeFactory.createUnaryOperatorNode(operator, operand)
  return { TYPE = "UnaryOperator", Value = operator, Operand = operand }
end
function NodeFactory.createOperatorNode(operator, left, right)
  return { TYPE = "Operator", Value = operator, Left = left, Right = right }
end
function NodeFactory.createFunctionCallNode(functionName, arguments)
  return { TYPE = "FunctionCall", FunctionName = functionName, Arguments = arguments }
end

return NodeFactory