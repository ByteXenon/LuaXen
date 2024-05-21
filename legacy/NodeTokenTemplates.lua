--[[
  Name: NodeTokenTemplates.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-18
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/ASTToTokensConverter/NodeTokenTemplates")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local TokenFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/TokenFactory")

--* Imports *--
local insert = table.insert

--* Import token factory functions *--
local createEOFToken = TokenFactory.createEOFToken
local createNewLineToken = TokenFactory.createNewLineToken
local createWhitespaceToken = TokenFactory.createWhitespaceToken
local createCommentToken = TokenFactory.createCommentToken
local createNumberToken = TokenFactory.createNumberToken
local createConstantToken = TokenFactory.createConstantToken
local createOperatorToken = TokenFactory.createOperatorToken
local createKeywordToken = TokenFactory.createKeywordToken
local createIdentifierToken = TokenFactory.createIdentifierToken
local createCharacterToken = TokenFactory.createCharacterToken
local createStringToken = TokenFactory.createStringToken

--* Local functions *--
local function insertTokensFromList(list, tokens)
  for index, token in ipairs(tokens) do
    insert(list, token)
  end
  return list
end

local function insertTokensWithCommas(tokens, items, createTokenFunc)
  for index, item in ipairs(items) do
    insert(tokens, createTokenFunc(item.Value))
    if index ~= #items then
      insert(tokens, createCharacterToken(","))
    end
  end
end

local function insertTokenizedNodesWithCommas(self, tokens, items)
  for index, item in ipairs(items) do
    insertTokensFromList(tokens, self:tokenizeNode(item))
    if index ~= #items then
      insert(tokens, createCharacterToken(","))
    end
  end
end

local function insertConditionAndCodeBlock(self, tokens, condition, codeBlock)
  insertTokensFromList(tokens, self:tokenizeNode(condition))
  insert(tokens, createKeywordToken("then"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(codeBlock))
end

local function shouldParenthesize(node, precedence, previousPrecedence)
  return node.Precedence
          and node.Precedence < precedence or previousPrecedence
          and previousPrecedence < precedence
end

local function insertParenthesizedTokens(self, tokens, node, precedence)
  if shouldParenthesize(node, precedence) then
    insert(tokens, createCharacterToken("("))
  end

  insertTokensFromList(tokens, self:tokenizeNode(node, precedence))

  if shouldParenthesize(node, precedence) then
    insert(tokens, createCharacterToken(")"))
  end
end

--* NodeTokenTemplates *--
local NodeTokenTemplates = {}

-- Number: { Value: "" }
function NodeTokenTemplates:Number(tokens, node)
  insert(tokens, node)
end

-- String: { Value: "" }
function NodeTokenTemplates:String(tokens, node)
  insert(tokens, node)
end

-- Constant: { Value: "" }
function NodeTokenTemplates:Constant(tokens, node)
  insert(tokens, node)
end

-- Variable: { VariableType: "", Value: "" }
function NodeTokenTemplates:Variable(tokens, node)
  insert(tokens, createIdentifierToken(node.Value))
end

-- Operator: { Value: "", Precedence: "", Left: "", Right: "" }
function NodeTokenTemplates:Operator(tokens, node, previousPrecedence)
  local left = node.Left
  local value = node.Value
  local right = node.Right
  local precedence = node.Precedence

  insertParenthesizedTokens(self, tokens, left, precedence)
  insert(tokens, createOperatorToken(value))
  insertParenthesizedTokens(self, tokens, right, precedence)
end

-- UnaryOperator: { Operand: "", Operator: "", Precedence: "" }
function NodeTokenTemplates:UnaryOperator(tokens, node, previousPrecedence)
  local operand = node.Operand
  local operator = node.Operator
  local precedence = node.Precedence

  insert(tokens, createOperatorToken(operator))
  insertParenthesizedTokens(self, tokens, operand, precedence)
end

-- LocalVariableAssignment: { Value: "" }
function NodeTokenTemplates:LocalVariableAssignment(tokens, node)
  insert(tokens, createKeywordToken("local"))
  insertTokensWithCommas(tokens, node.Variables, createIdentifierToken)

  if node.Expressions and #node.Expressions > 0 then
    insert(tokens, createCharacterToken("="))
    insertTokenizedNodesWithCommas(self, tokens, node.Expressions)
  end
end

-- IfStatement: { Condition: "", CodeBlock: "", ElseIfs: "", Else: "" }
function NodeTokenTemplates:IfStatement(tokens, node)
  insert(tokens, createKeywordToken("if"))
  insertConditionAndCodeBlock(self, tokens, node.Condition, node.CodeBlock)
  for _, elseIf in ipairs(node.ElseIfs) do
    insert(tokens, createKeywordToken("elseif"))
    insertConditionAndCodeBlock(self, tokens, elseIf.Condition, elseIf.CodeBlock)
  end
  if node.Else and node.Else.TYPE then
    insert(tokens, createKeywordToken("else"))
    insertTokensFromList(tokens, self:tokenizeCodeBlock(node.Else.CodeBlock))
  end
  insert(tokens, createKeywordToken("end"))
end

-- LocalFunction: { Name: "", Parameters: "", IsVararg: "", CodeBlock: "" }
function NodeTokenTemplates:LocalFunction(tokens, node)
  insert(tokens, createKeywordToken("local"))
  insert(tokens, createKeywordToken("function"))
  insert(tokens, createIdentifierToken(node.Name))
  insert(tokens, createCharacterToken("("))
  for index, param in ipairs(node.Parameters) do
    insert(tokens, createIdentifierToken(param))
    if index ~= #node.Parameters then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, createKeywordToken("end"))
end

-- FunctionDeclaration: { Parameters: "", IsVararg: "", CodeBlock: "", Fields: "" }
function NodeTokenTemplates:FunctionDeclaration(tokens, node)
  insert(tokens, createKeywordToken("function"))
  for index, field in ipairs(node.Fields) do
    insert(tokens, createIdentifierToken(field))
    if index <= (#node.Fields - 1) then
      insert(tokens, createCharacterToken("."))
    end
  end
  insert(tokens, createCharacterToken("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, createConstantToken("..."))
    else                   insert(tokens, createIdentifierToken(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, createKeywordToken("end"))
end

-- MethodDeclaration: { Parameters: "", IsVararg: "", CodeBlock: "", Fields: "" }
function NodeTokenTemplates:MethodDeclaration(tokens, node)
  insert(tokens, createKeywordToken("function"))
  for index, field in ipairs(node.Fields) do
    insert(tokens, createIdentifierToken(field))
    if index == (#node.Fields - 1) then
      insert(tokens, createCharacterToken(":"))
    elseif index ~= #node.Fields then
      insert(tokens, createCharacterToken("."))
    end
  end
  insert(tokens, createCharacterToken("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, createConstantToken("..."))
    else                   insert(tokens, createIdentifierToken(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, createKeywordToken("end"))
end

-- VariableAssignment: { Variables: "", Expressions: "" }
function NodeTokenTemplates:VariableAssignment(tokens, node)
  for index, variable in ipairs(node.Variables) do
    insertTokensFromList(tokens, self:tokenizeNode(variable))
    if index ~= #node.Variables then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken("="))
  for index, expression in ipairs(node.Expressions) do
    insertTokensFromList(tokens, self:tokenizeNode(expression))
    if index ~= #node.Expressions then
      insert(tokens, createCharacterToken(","))
    end
  end
end

-- Function: { Parameters: "", IsVararg: "", CodeBlock: "" }
function NodeTokenTemplates:Function(tokens, node)
  insert(tokens, createKeywordToken("function"))
  insert(tokens, createCharacterToken("("))
  for index, param in ipairs(node.Parameters) do
    if param == "..." then insert(tokens, createConstantToken("..."))
    else                   insert(tokens, createIdentifierToken(param))
    end

    if index ~= #node.Parameters then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, createKeywordToken("end"))
end

-- FunctionCall: { Expression: "", Arguments: "" }
function NodeTokenTemplates:FunctionCall(tokens, node)
  local expression = node.Expression
  local arguments = node.Arguments

  if expression.TYPE ~= "Variable" and expression.TYPE ~= "Index" then
    insert(tokens, createCharacterToken("("))
  end
  insertTokensFromList(tokens, self:tokenizeNode(expression))
  if expression.TYPE ~= "Variable" and expression.TYPE ~= "Index" then
    insert(tokens, createCharacterToken(")"))
  end
  insert(tokens, createCharacterToken("("))
  for index, parameter in ipairs(arguments) do
    insertTokensFromList(tokens, self:tokenizeNode(parameter))
    if index ~= #arguments then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
end

-- MethodCall: { Expression: "", Arguments: "" }
function NodeTokenTemplates:MethodCall(tokens, node)
  local expression = node.Expression
  local arguments = node.Arguments

  if expression.TYPE ~= "Variable" and expression.TYPE ~= "Index" and expression.TYPE ~= "MethodIndex" then
    insert(tokens, createCharacterToken("("))
  end
  insertTokensFromList(tokens, self:tokenizeNode(expression))
  if expression.TYPE ~= "Variable" and expression.TYPE ~= "Index" and expression.TYPE ~= "MethodIndex" then
    insert(tokens, createCharacterToken(")"))
  end
  insert(tokens, createCharacterToken("("))
  for index, parameter in ipairs(arguments) do
    insertTokensFromList(tokens, self:tokenizeNode(parameter))
    if index ~= #arguments then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken(")"))
end

-- WhileLoop: { Expression: "", CodeBlock: "" }
function NodeTokenTemplates:WhileLoop(tokens, node)
  local expression = self:tokenizeNode(node.Expression)
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)

  insert(tokens, createKeywordToken("while"))
  insertTokensFromList(tokens, expression)
  insert(tokens, createKeywordToken("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, createKeywordToken("end"))
end

-- GenericFor: { IteratorVariables: "", Expressions: "", CodeBlock: "" }
function NodeTokenTemplates:GenericFor(tokens, node)
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions

  insert(tokens, createKeywordToken("for"))
  for index, variableName in ipairs(iteratorVariables) do
    insert(tokens, createIdentifierToken(variableName))
    if index ~= #iteratorVariables then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createKeywordToken("in"))
  for index, expression in ipairs(expressions) do
    insertTokensFromList(tokens, self:tokenizeNode(expression))
    if index ~= #expressions then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createKeywordToken("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, createKeywordToken("end"))
end

-- NumericFor: { IteratorVariables: "", Expressions: "", CodeBlock: "" }
function NodeTokenTemplates:NumericFor(tokens, node)
  local expressions = node.Expressions
  local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
  local iteratorVariables = node.IteratorVariables

  insert(tokens, createKeywordToken("for"))
  for index, variableName in ipairs(iteratorVariables) do
    insert(tokens, createIdentifierToken(variableName))
    if index ~= #iteratorVariables then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken("="))
  for index, token in ipairs(expressions) do
    insertTokensFromList(tokens, self:tokenizeNode(token))
    if index ~= #expressions then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createKeywordToken("do"))
  insertTokensFromList(tokens, codeBlock)
  insert(tokens, createKeywordToken("end"))
end

-- Table: { Elements: "" }
function NodeTokenTemplates:Table(tokens, node)
  insert(tokens, createCharacterToken("{"))
  for index, element in ipairs(node.Elements) do
    if element.ImplicitKey then
      insertTokensFromList(tokens, self:tokenizeNode(element.Value))
    else
      insert(tokens, createCharacterToken("["))
      insertTokensFromList(tokens, self:tokenizeNode(element.Key))
      insert(tokens, createCharacterToken("]"))
      insert(tokens, createCharacterToken("="))
      insertTokensFromList(tokens, self:tokenizeNode(element.Value))
    end
    if index ~= #node.Elements then
      insert(tokens, createCharacterToken(","))
    end
  end
  insert(tokens, createCharacterToken("}"))
end

-- DoBlock: { CodeBlock: "" }
function NodeTokenTemplates:DoBlock(tokens, node)
  insert(tokens, createKeywordToken("do"))
  insertTokensFromList(tokens, self:tokenizeCodeBlock(node.CodeBlock))
  insert(tokens, createKeywordToken("end"))
end

-- Index: { Expression: "", Index: "" }
function NodeTokenTemplates:Index(tokens, node)
  insertTokensFromList(tokens, self:tokenizeNode(node.Expression))
  if node.Index.TYPE == "String" and node.Index.Value:match("^[%a_].*") then
    insert(tokens, createCharacterToken("."))
    insert(tokens, createIdentifierToken(node.Index.Value))
  else
    insert(tokens, createCharacterToken("["))
    insertTokensFromList(tokens, self:tokenizeNode(node.Index))
    insert(tokens, createCharacterToken("]"))
  end
end

-- MethodIndex: { Expression: "", Index: "" }
function NodeTokenTemplates:MethodIndex(tokens, node)
  insertTokensFromList(tokens, self:tokenizeNode(node.Expression))
  insert(tokens, createCharacterToken(":"))
  if node.Index.TYPE == "String" and node.Index.Value:match("^[%a_].*") then
    insert(tokens, createIdentifierToken(node.Index.Value))
  else
    insertTokensFromList(tokens, self:tokenizeNode(node.Index))
  end
end

-- ReturnStatement: { Expressions: "" }
function NodeTokenTemplates:ReturnStatement(tokens, node)
  insert(tokens, createKeywordToken("return"))
  insertTokenizedNodesWithCommas(self, tokens, node.Expressions)
end

-- BreakStatement: { }
function NodeTokenTemplates:BreakStatement(tokens, node)
  insert(tokens, createKeywordToken("break"))
end

-- ContinueStatement: { }
function NodeTokenTemplates:ContinueStatement(tokens, node)
  insert(tokens, createKeywordToken("continue"))
end


return NodeTokenTemplates