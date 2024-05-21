--[[
  Name: StatementNodesConverters.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-10
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local concat = table.concat

--* StatementNodesConverters *--
local StatementNodesConverters = {}

function StatementNodesConverters:IfStatement(node)
  local elseIfStatements = ""
  for _, elseIf in ipairs(node.ElseIfs) do
    elseIfStatements = elseIfStatements .. self.indentation .. "elseif " .. self:processExpressionNode(elseIf.Condition) .. " then\n"
      .. self:processCodeBlock(elseIf.CodeBlock)
  end
  if node.Else then
    elseIfStatements = elseIfStatements .. self.indentation .. "else\n"
      .. self:processCodeBlock(node.Else.CodeBlock)
    end

  return self.indentation .. "if " .. self:processExpressionNode(node.Condition) .. " then\n"
            .. self:processCodeBlock(node.CodeBlock)
            .. elseIfStatements
        .. self.indentation  .. "end"
end
function StatementNodesConverters:WhileLoop(node)
  return self.indentation .. "while " .. self:processExpressionNode(node.Expression) .. " do\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:DoBlock(node)
  return self.indentation .. "do\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:UntilLoop(node)
  return self.indentation .. "repeat\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "until " .. self:processExpressionNode(node.Statement)
end

function StatementNodesConverters:FunctionCall(node)
  local expressionType = node.Expression.TYPE
  if expressionType ~= "Variable" and expressionType ~= "Index" and expressionType ~= "MethodIndex" then
    return self.indentation .. "(" .. self:processExpressionNode(node.Expression) .. ")("
            .. self:processExpressions(node.Arguments) .. ")"
  end
  return self.indentation .. self:processExpressionNode(node.Expression) .. "("
            .. self:processExpressions(node.Arguments) .. ")"
end

function StatementNodesConverters:MethodCall(node)
  return self.indentation .. self:processExpressionNode(node.Expression) .. "("
            .. self:processExpressions(node.Arguments) .. ")"
end

function StatementNodesConverters:LocalVariableAssignment(node)
  if #node.Expressions == 0 then
    return self.indentation .. "local " .. self:processIdentifierList(node.Variables)
  end

  return self.indentation .. "local " .. self:processIdentifierList(node.Variables) .. " = "
            .. self:processExpressions(node.Expressions)
end

function StatementNodesConverters:VariableAssignment(node)
  return self.indentation .. self:processExpressions(node.Variables) .. " = "
            .. self:processExpressions(node.Expressions)
end

function StatementNodesConverters:ReturnStatement(node)
  return self.indentation .. "return " .. self:processExpressions(node.Expressions)
end

function StatementNodesConverters:BreakStatement(node)
  return self.indentation .. "break"
end

function StatementNodesConverters:ContinueStatement(node)
  return self.indentation .. "continue"
end

function StatementNodesConverters:NumericFor(node)
  return self.indentation .. "for " .. self:processIdentifierList(node.IteratorVariables) .. " = "
            .. self:processExpressions(node.Expressions) .. " do\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:GenericFor(node)
  return self.indentation .. "for " .. self:processIdentifierList(node.IteratorVariables) .. " in "
            .. self:processExpressions(node.Expressions) .. " do\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:LocalFunction(node)
  local newParameters = {}
  for _, parameter in ipairs(node.Parameters) do
    insert(newParameters, parameter)
  end
  if node.IsVararg then
    insert(newParameters, "...")
  end

  return self.indentation .. "local function " .. node.Name .. "("
            .. self:processIdentifierList(newParameters) .. ")\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:FunctionDeclaration(node)
  local newParameters = {}
  for _, parameter in ipairs(node.Parameters) do
    insert(newParameters, parameter)
  end
  if node.IsVararg then
    insert(newParameters, "...")
  end

  return self.indentation .. "function " .. self:processExpressionNode(node.Expression) .. "." .. concat(node.Fields, ".")  .. "("
            .. self:processIdentifierList(newParameters) .. ")\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

function StatementNodesConverters:MethodDeclaration(node)
  local fields = {}
  for index, value in ipairs(node.Fields) do
    if index ~= #node.Fields then
      fields[index] = "." .. value
    else
      fields[index] = ":" .. value
    end
  end
  local newParameters = {}
  for _, parameter in ipairs(node.Parameters) do
    insert(newParameters, parameter)
  end
  if node.IsVararg then
    insert(newParameters, "...")
  end

  return self.indentation .. "function " .. self:processExpressionNode(node.Expression)
            .. concat(fields) .. "("
            .. self:processIdentifierList(newParameters) .. ")\n"
            .. self:processCodeBlock(node.CodeBlock)
        .. self.indentation .. "end"
end

return StatementNodesConverters