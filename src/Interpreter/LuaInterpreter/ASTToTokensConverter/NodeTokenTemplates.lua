--[[
  Name: NodeTokenTemplates.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/ASTToTokensConverter/NodeTokenTemplates")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert

local function insertTokensFromList(list, tokens)
  for index, token in ipairs(tokens) do
    insert(list, token)
  end
  return list
end

--* NodeTokenTemplates *--
local NodeTokenTemplates = {}
function NodeTokenTemplates:Identifier(tokens, node)
  insert(tokens, self:newIdentifier(node.Value))
end
function NodeTokenTemplates:Number(tokens, node)
  insert(tokens, self:newNumber(node.Value))
end
function NodeTokenTemplates:String(tokens, node)
  insert(tokens, self:newString(node.Value))
end
function NodeTokenTemplates:Constant(tokens, node)
  insert(tokens, self:newConstant(node.Value))
end
function NodeTokenTemplates:Operator(tokens, node, previousPrecedence)
  local currentPrecedence = node.Precedence
  local placeParentheses = previousPrecedence and (currentPrecedence < previousPrecedence)
  if placeParentheses then
    insert(tokens, self:newCharacter("("))
  end

  if node.Left.TYPE == "Operator" then
    self:Operator(tokens, node.Left, currentPrecedence)
  else
    insertTokensFromList(tokens, self:tokenizeNode(node.Left))
  end
  insert(tokens, self:newOperator(node.Value))

  if node.Right.TYPE == "Operator" then
    self:Operator(tokens, node.Right, currentPrecedence)
  else
    insertTokensFromList(tokens, self:tokenizeNode(node.Right))
  end

  if placeParentheses then
    insert(tokens, self:newCharacter(")"))
  end
end
function NodeTokenTemplates:UnaryOperator(tokens, node)
  local operand = self:tokenizeNode(node.Operand)
  insert(tokens, self:newOperator(node.Value))
  insertTokensFromList(tokens, operand)
end
function NodeTokenTemplates:LocalVariable(tokens, node)
  insert(tokens, self:newKeyword("local"))
  for index, variable in ipairs(node.Variables) do
    insert(tokens, self:newIdentifier(variable.Value))
    if index ~= #node.Variables then insert(tokens, self:newCharacter(",")) end
  end
  insert(tokens, self:newCharacter("="))
  for index, expression in ipairs(node.Expressions) do
    local tokenizedExpression = self:tokenizeNode(expression)
    insertTokensFromList(tokens, tokenizedExpression)
    if index ~= #node.Expressions then insert(tokens, self:newCharacter(",")) end
  end
end
function NodeTokenTemplates:IfStatement(tokens, node)
  insert(tokens, self:newKeyword("if"))
  insertTokensFromList(tokens, self:tokenizeNode(node.Condition))
  insert(tokens, self:newKeyword("then"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  for _, elseIf in ipairs(node.ElseIfs) do
    insert(tokens, self:newKeyword("elseif"))
    insertTokensFromList(tokens, self:tokenizeNode(elseIf.Condition))
    insert(tokens, self:newKeyword("then"))
    insertTokensFromList(tokens, self:tokenizeCodeBlock(elseIf.CodeBlock))
  end
  if node.Else and node.Else.TYPE then
    insert(tokens, self:newKeyword("else"))
    print(node.Else.CodeBlock)
    insertTokensFromList(tokens, self:tokenizeCodeBlock(node.Else.CodeBlock))
  end
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:LocalFunction(tokens, node)
  insert(tokens, self:newKeyword("local"))
  insert(tokens, self:newKeyword("function"))
  insert(tokens, self:newIdentifier(node.Name))
  insert(tokens, self:newCharacter("("))
  for index, param in ipairs(node.Parameters) do
    insert(tokens, self:newIdentifier(param))
    if index ~= #node.Parameters then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newCharacter(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:FunctionDeclaration(tokens, node)
  insert(tokens, self:newKeyword("function"))
  for index, field in ipairs(node.Fields) do
    insert(tokens, self:newIdentifier(field))
    if index <= (#node.Fields - 1) then
      insert(tokens, self:newCharacter("."))
    end
  end
  insert(tokens, self:newCharacter("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, self:newConstant("..."))
    else                   insert(tokens, self:newIdentifier(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newCharacter(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:VariableAssignment(tokens, node)
  for index, variable in ipairs(node.Variables) do
    insertTokensFromList(tokens, self:tokenizeNode(variable))
    if index ~= #node.Variables then insert(tokens, self:newCharacter(",")) end
  end
  insert(tokens, self:newCharacter("="))
  for index, expression in ipairs(node.Expressions) do
    local tokenizedExpression = self:tokenizeNode(expression)
    insertTokensFromList(tokens, tokenizedExpression)
    if index ~= #node.Expressions then insert(tokens, self:newCharacter(",")) end
  end
end
function NodeTokenTemplates:MethodDeclaration(tokens, node)
  insert(tokens, self:newKeyword("function"))
  for index, field in ipairs(node.Fields) do
    insert(tokens, self:newIdentifier(field))
    if index == (#node.Fields - 1) then
      insert(tokens, self:newCharacter(":"))
    elseif index ~= #node.Fields then
      insert(tokens, self:newCharacter("."))
    end
  end
  insert(tokens, self:newCharacter("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, self:newConstant("..."))
    else                   insert(tokens, self:newIdentifier(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newCharacter(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:Function(tokens, node)
  insert(tokens, self:newKeyword("function"))
  insert(tokens, self:newCharacter("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, self:newConstant("..."))
    else                   insert(tokens, self:newIdentifier(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newCharacter(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:FunctionCall(tokens, node)
  local expression = node.Expression
  local arguments = node.Arguments

  if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" then
    insert(tokens, self:newCharacter("("))
  end
  insertTokensFromList(tokens, self:tokenizeNode(expression))
  if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" then
    insert(tokens, self:newCharacter(")"))
  end
  insert(tokens, self:newCharacter("("))
  for index, parameter in ipairs(arguments) do
    insertTokensFromList(tokens, self:tokenizeNode(parameter))
    if index ~= #arguments then insert(tokens, self:newCharacter(",")) end
  end
  insert(tokens, self:newCharacter(")"))
end
function NodeTokenTemplates:MethodCall(tokens, node)
  local expression = node.Expression
  local arguments = node.Arguments

  if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" and expression.TYPE ~= "MethodIndex" then
    insert(tokens, self:newCharacter("("))
  end
  insertTokensFromList(tokens, self:tokenizeNode(expression))
  if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" and expression.TYPE ~= "MethodIndex" then
    insert(tokens, self:newCharacter(")"))
  end
  insert(tokens, self:newCharacter("("))
  for index, parameter in ipairs(arguments) do
    insertTokensFromList(tokens, self:tokenizeNode(parameter))
    if index ~= #arguments then insert(tokens, self:newCharacter(",")) end
  end
  insert(tokens, self:newCharacter(")"))
end
function NodeTokenTemplates:WhileLoop(tokens, node)
  local expression = self:tokenizeNode(node.Expression)
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)

  insert(tokens, self:newKeyword("while"))
  insertTokensFromList(tokens, expression)
  insert(tokens, self:newKeyword("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:GenericFor(tokens, node)
  local expression = self:tokenizeNode(node.Expression)
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
  local iteratorVariables = node.IteratorVariables

  insert(tokens, self:newKeyword("for"))
  for index, variableName in ipairs(iteratorVariables) do
    insert(tokens, self:newIdentifier(variableName))
    if index ~= #iteratorVariables then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newKeyword("in"))
  insertTokensFromList(tokens, expression)
  insert(tokens, self:newKeyword("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:NumericFor(tokens, node)
  local expressions = node.Expressions
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
  local iteratorVariables = node.IteratorVariables

  insert(tokens, self:newKeyword("for"))
  for index, variableName in ipairs(iteratorVariables) do
    insert(tokens, self:newIdentifier(variableName))
    if index ~= #iteratorVariables then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newCharacter("="))
  for index, token in ipairs(expressions) do
    insertTokensFromList(tokens, self:tokenizeNode(token))
    if index ~= #expressions then
      insert(tokens, self:newCharacter(","))
    end
  end
  insert(tokens, self:newKeyword("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:Table(tokens, node)
  insert(tokens, self:newCharacter("{"))
  for index, element in ipairs(node.Elements) do
    insert(tokens, self:newCharacter("["))
    insertTokensFromList(tokens, self:tokenizeNode(element.Key))
    insert(tokens, self:newCharacter("]"))
    insert(tokens, self:newCharacter("="))
    insertTokensFromList(tokens, self:tokenizeNode(element.Value))
    if index ~= #node.Elements then insert(tokens, self:newCharacter(",")) end
  end
  insert(tokens, self:newCharacter("}"))
end
function NodeTokenTemplates:ReturnStatement(tokens, node)
  insert(tokens, self:newKeyword("return"))
  for index, expression in ipairs(node.Expressions) do
    insertTokensFromList(tokens, self:tokenizeNode(expression))
    if index ~= #node.Expressions then insert(tokens, self:newCharacter(",")) end
  end
end
function NodeTokenTemplates:DoBlock(tokens, node)
  insert(tokens, self:newKeyword("do"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, self:newKeyword("end"))
end
function NodeTokenTemplates:Index(tokens, node)
  insertTokensFromList(tokens, self:tokenizeNode(node.Expression))
  if node.Index.TYPE == "String" and node.Index.Value:match("^[%a_].*") then
    insert(tokens, self:newCharacter("."))
    insert(tokens, self:newIdentifier(node.Index.Value))
  else
    insert(tokens, self:newCharacter("["))
    insertTokensFromList(tokens, self:tokenizeNode(node.Index))
    insert(tokens, self:newCharacter("]"))
  end
end
function NodeTokenTemplates:MethodIndex(tokens, node)
  insertTokensFromList(tokens, self:tokenizeNode(node.Expression))
  insert(tokens, self:newCharacter(":"))
  if node.Index.TYPE == "String" and node.Index.Value:match("^[%a_].*") then
    insert(tokens, self:newIdentifier(node.Index.Value))
  else
    insertTokensFromList(tokens, self:tokenizeNode(node.Index))
  end
end
function NodeTokenTemplates:BreakStatement(tokens, node)
  insert(tokens, self:newKeyword("break"))
end

return NodeTokenTemplates