--[[
  NodeTransformations.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is responsible for transforming the AST into a format that can be executed by the LuaInterpreter.
    It provides methods for transforming ASTs.
--]]

local NodeTransformations = {}

-- Adds "amountOfReturnValues" to the node to indicate the number of return values
function NodeTransformations:FunctionCall(node)
  local amountOfReturnValues = 1
  

  node.NumberOfReturnValues = numberOfReturnValues
end

function NodeTransformations:LocalVariable(node)
  local expressions = node.Expressions
  local variables = node.Variables

  for _, variableNode in ipairs(variables) do
    if variableNode.TYPE == "Identifier" then
      local variableName = variableNode.Value

      self:registerVariable(variableName)
    end
  end
end

-- Converts an identifier to either a LocalVariable, GlobalVariable, or Upvalue
function NodeTransformations:Identifier(node)
  local variableName = node.Value
  local nodeIndex = node._methods:getInternalField("index")

  -- Ignore identifiers in the "Variables" field of a LocalVariable node
  if nodeIndex == "Variables" then
    return
  end

  node.TYPE = self:checkVariable(variableName)
end

return NodeTransformations