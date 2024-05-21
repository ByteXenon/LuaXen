--[[
  Name: ExpressionNodesConverters.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]


--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local sanitizeString = Helpers.sanitizeString
local insert = table.insert
local concat = table.concat

--* ExpressionNodesConverters *--
local ExpressionNodesConverters = {}

function ExpressionNodesConverters:Number(node)
  return tostring(node.Value)
end

function ExpressionNodesConverters:Variable(node)
  return tostring(node.Value)
end

function ExpressionNodesConverters:Constant(node)
  return tostring(node.Value)
end

function ExpressionNodesConverters:VarArg(node)
  return "..."
end

function ExpressionNodesConverters:String(node)
  local delimiter = node.Delimiter or "\""
  return delimiter .. sanitizeString(node.Value, delimiter) .. delimiter
end

function ExpressionNodesConverters:Index(node)
  local shouldntPutInBrackets = node.Index.TYPE == "String" and node.Index.Value:match("^[%a_][%w_]*$")
  local index = (shouldntPutInBrackets and node.Index.Value) or self:processExpressionNode(node.Index)
  local indexString = (shouldntPutInBrackets and "." .. index) or "[" .. index .. "]"
  return self:processExpressionNode(node.Expression) .. indexString
end

function ExpressionNodesConverters:MethodIndex(node)
  return self:processExpressionNode(node.Expression) .. ":" .. node.Index.Value
end

function ExpressionNodesConverters:UnaryOperator(node)
  if node.Value == "not" then
    return "not " .. self:processExpressionNode(node.Operand)
  end

  return node.Value .. self:processExpressionNode(node.Operand)
end

function ExpressionNodesConverters:Operator(node)
  local nodeValue = node.Value
  -- A special case with extra spaces for "and" and "or" operators so stuff wont break
  if nodeValue == "and" or nodeValue == "or" then
    return self:processExpressionNode(node.Left) .. " " .. nodeValue .. " " .. self:processExpressionNode(node.Right)
  end

  return self:processExpressionNode(node.Left) .. " " .. node.Value .. " " .. self:processExpressionNode(node.Right)
end

function ExpressionNodesConverters:Function(node)
  local newParameters = {}
  for _, parameter in ipairs(node.Parameters) do
    insert(newParameters, parameter)
  end
  if node.IsVararg then
    insert(newParameters, "...")
  end

  return "function(" .. self:processIdentifierList(newParameters) .. ")\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function ExpressionNodesConverters:FunctionCall(node)
  local expressionType = node.Expression.TYPE
  if expressionType ~= "Variable" and expressionType ~= "Index" and expressionType ~= "MethodIndex" then
    return "(" .. self:processExpressionNode(node.Expression) .. ")("
            .. self:processExpressions(node.Arguments) .. ")"
  end
  return self:processExpressionNode(node.Expression) .. "("
            .. self:processExpressions(node.Arguments) .. ")"
end

function ExpressionNodesConverters:MethodCall(node)
  return self:processExpressionNode(node.Expression) .. "("
            .. self:processExpressions(node.Arguments) .. ")"
end

function ExpressionNodesConverters:Table(node)
  local tb = {}
  for _, element in ipairs(node.Elements) do
    local isImplicitKey = element.ImplicitKey
    if isImplicitKey then
      insert(tb, self:processExpressionNode(element.Value))
    else
      local elementIndex = self:processExpressionNode(element.Key)
      local elementValue = self:processExpressionNode(element.Value)
      insert(tb, "[" .. elementIndex .. "] = " .. elementValue)
    end
  end
  return "{" .. concat(tb, ", ") .. "}"
end

return ExpressionNodesConverters