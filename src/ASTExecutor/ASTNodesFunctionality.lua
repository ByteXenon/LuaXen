--[[
  Name: ASTNodesFunctionality.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-07
  Description:
    This internal module provides specific functions for executing different types of AST nodes.
    Each function corresponds to a particular type of AST node and contains the logic to execute
    that node within the context of a Lua script. This module is exclusively utilized by the
    ASTExecutor module to interpret and execute the AST.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local unpack = (unpack or table.unpack)

--* Local functions *--
local function customUnpack(table, numberOfValues)
  local numberOfValues = numberOfValues or #table
  local function unpackHelper(startIndex)
    if startIndex > numberOfValues then return end
    return table[startIndex], unpackHelper(startIndex + 1, numberOfValues)
  end
  return unpackHelper(1)
end

--* ASTNodesFunctionality *--
local ASTNodesFunctionality = {}

-----------------// Flow Control \\-----------------

-- ContinueStatement: {}
function ASTNodesFunctionality:ContinueStatement(node)
  self.flags.continueFlag = true
end

-- BreakStatement: {}
function ASTNodesFunctionality:BreakStatement(node)
  self.flags.breakFlag = true
end

-- ReturnStatement: { Expressions: {} }
function ASTNodesFunctionality:ReturnStatement(node)
  local expressions = node.Expressions

  local results, returnValuesAmount = self:executeExpressionNodes(expressions)
  self.returnValues = results
  self.returnValuesAmount = returnValuesAmount
  self.flags.returnFlag = true
end

-----------------// Literal and Identifier Nodes \\-----------------

-- Constant: { Value: "" }
function ASTNodesFunctionality:Constant(node)
  local value = node.Value
  if value == true or value == false then
    return value
  elseif value == "true" or value == "false" then
    return value == "true"
  end
  return nil
end

-- Boolean: { Value: "" }
function ASTNodesFunctionality:Boolean(node)
  return node.Value
end

-- Identifier: { Value: "" }
function ASTNodesFunctionality:Identifier(node)
  -- local value = node.Value
  -- return self:getVariable(value, state)
  error("Identifiers are not supported in newer ASTExecutor versions")
end

-- Number: { Value: "" }
function ASTNodesFunctionality:Number(node)
  return tonumber(node.Value)
end

-- String: { Value: "" }
function ASTNodesFunctionality:String(node)
  return tostring(node.Value)
end

-- Table: { Elements: {} }
function ASTNodesFunctionality:Table(node)
  local elements = node.Elements

  local newTable = {}

  -- TableElement: { Key: {}, Value: {}, ImplicitKey: "" }
  for _, element in ipairs(elements) do
    local elementKey = element.Key
    local elementValue = element.Value
    local implicitKey = element.ImplicitKey
    if implicitKey then
      local values = { self:executeExpressionNode(elementValue) }
      local index = self:executeExpressionNode(elementKey)
      for _, value in ipairs(values) do
        newTable[index] = value
        index = index + 1
      end
    else
      local key = self:executeExpressionNode(elementKey)
      local value = self:executeExpressionNode(elementValue)
      newTable[key] = value
    end
  end

  return newTable
end

-----------------// Variable Access \\-----------------

-- VarArg: {}
function ASTNodesFunctionality:VarArg(node)
  return self:getVarArg()
end

-- Variable: { VariableType: "", Value: "" }
function ASTNodesFunctionality:Variable(node)
  local variableType = node.VariableType
  local value = node.Value

  local variableValue -- For easier debugging, put the value of the variable here
  if variableType == "Global" then
    variableValue = self:getGlobalVariable(value)
  elseif variableType == "Local" then
    variableValue = self:getLocalVariable(value)
  elseif variableType == "Upvalue" then
    variableValue = self:getUpvalue(value)
  end
  return variableValue
end

-----------------// Table Indexing \\-----------------

-- A one function for both "Index" and "MethodIndex" nodes.
-- Index|MethodIndex: { Expression: {}, Index: {} }
local function indexNode(self, node)
  local index = node.Index
  local expression = self:executeExpressionNode(node.Expression)
  local expressionType = type(expression)

  -- Check expression type before indexing
  if expressionType ~= "table" and expressionType ~= "string" and expressionType ~= "userdata" then
    return error("attempt to index variable (a " .. expressionType .. " value)")
  end

  local evaluatedIndex = self:executeExpressionNode(index)
  if not evaluatedIndex then
    local indexType = type(evaluatedIndex)
    return error("attempt to index variable with " .. indexType)
  end

  return expression[evaluatedIndex]
end

-- Index: { Expression: {}, Index: {} }
function ASTNodesFunctionality:Index(node)
  local index = node.Index
  local expression = self:executeExpressionNode(node.Expression)
  local expressionType = type(expression)

  -- Check expression type before indexing
  if expressionType ~= "table" and expressionType ~= "string" and expressionType ~= "userdata" then
    return error("attempt to index variable (a " .. expressionType .. " value)")
  end

  local evaluatedIndex = self:executeExpressionNode(index)
  if not evaluatedIndex then
    local indexType = type(evaluatedIndex)
    return error("attempt to index variable with " .. indexType)
  end

  return expression[evaluatedIndex]
end

-- MethodIndex: { Expression: {}, Index: {} }
function ASTNodesFunctionality:MethodIndex(node)
  local index = node.Index
  local expression = self:executeExpressionNode(node.Expression)
  local expressionType = type(expression)

  -- Check expression type before indexing
  if expressionType ~= "table" and expressionType ~= "string" and expressionType ~= "userdata" then
    return error("attempt to index variable (a " .. expressionType .. " value)")
  end

  local evaluatedIndex = self:executeExpressionNode(index)
  if not evaluatedIndex then
    local indexType = type(evaluatedIndex)
    return error("attempt to index variable with " .. indexType)
  end

  return expression[evaluatedIndex]
end

-----------------// Operators \\-----------------

-- Operator: { Left: {}, Right: {}, Value: "" }
function ASTNodesFunctionality:Operator(node)
  local operator = node.Value
  local left = self:executeExpressionNode(node.Left)
  local right
  -- For optimization purposes, we only execute the right node if the operator is not "and" or "or"
  -- The default Lua behavior is the same.
  if operator ~= "and" and operator ~= "or" then
    right = self:executeExpressionNode(node.Right)
  end

  -- it's just better to use raw IFs rather than a table
  -- with mapped functions. /:
  -- If you wanna optimize it, you know what you have to do.
  if     operator == "+"   then return left +  right
  elseif operator == "-"   then return left -  right
  elseif operator == "*"   then return left *  right
  elseif operator == "/"   then return left /  right
  elseif operator == "^"   then return left ^  right
  elseif operator == "%"   then return left %  right
  elseif operator == ".."  then return left .. right
  elseif operator == "=="  then return left == right
  elseif operator == "~="  then return left ~= right
  elseif operator == "<"   then return left <  right
  elseif operator == ">"   then return left >  right
  elseif operator == "<="  then return left <= right
  elseif operator == ">="  then return left >= right
  elseif operator == "and" then
    if not left then return left end
    return left and self:executeExpressionNode(node.Right)
  elseif operator == "or"  then
    if left then return left end
    return left or self:executeExpressionNode(node.Right)
  else
    return error("Invalid operator: " .. operator)
  end
end

-- UnaryOperator: { Operand: {}, Value: "" }
function ASTNodesFunctionality:UnaryOperator(node)
  local operator = node.Value
  local operand = self:executeExpressionNode(node.Operand)

  if     operator == "-"   then return -   operand
  elseif operator == "not" then return not operand
  elseif operator == "#"   then return #   operand
  else
    return error("Invalid unary operator: " .. tostring(operator))
  end
end

-----------------// Function Definitions \\-----------------

-- Function: { Parameters: {}, IsVararg: "", CodeBlock: {} }
function ASTNodesFunctionality:Function(node)
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local codeBlock = node.CodeBlock

  return self:makeLuaFunction(parameters, isVararg, codeBlock)
end

-- LocalFunction: { Name: {}, Parameters: {}, IsVararg: "", CodeBlock: {} }
function ASTNodesFunctionality:LocalFunction(node)
  local name = node.Name
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local codeBlock = node.CodeBlock

  local newFunction = self:makeLuaFunction(parameters, isVararg, codeBlock)

  return self:registerVariable(name, newFunction)
end

-- FunctionDeclaration: { Fields: {}, Parameters: {}, IsVararg: "", CodeBlock: {}, Expression: {} }
function ASTNodesFunctionality:FunctionDeclaration(node)
  local fields = node.Fields
  local codeBlock = node.CodeBlock
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local expression = node.Expression

  local newFunction = self:makeLuaFunction(parameters, isVararg, codeBlock)

  -- If the function is not in a table, just declare it
  if #fields == 0 then
    return self:changeVariable(expression, newFunction)
  end

  local lastField = fields[#fields]
  local tableToModify = self:getVariable(expression.Value)

  -- Traverse the fields to find the table to modify
  for index = 1, #fields - 1 do
    local fieldName = fields[index]
    local fieldType = type(tableToModify[fieldName])
    if fieldType ~= "table" then
      return error("Expected a table, got " .. fieldType)
    end
    tableToModify = tableToModify[fieldName]
  end
  -- Assign the new function to the last field in the table
  tableToModify[lastField] = newFunction
end

-- MethodDeclaration: { Fields: {}, Parameters: {}, IsVararg: "", CodeBlock: {}, Expression: {} }
function ASTNodesFunctionality:MethodDeclaration(node)
  local fields = node.Fields
  local codeBlock = node.CodeBlock
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local expression = node.Expression

  local newParameters = {"self"}

  -- Copy parameters to newParameters, starting from index 2
  for index, value in ipairs(parameters) do
    newParameters[index + 1] = value
  end

  -- Make a function: function(self, <parameters>) <codeBlock> end
  local newFunction = self:makeLuaFunction(newParameters, isVararg, codeBlock)

  local lastField = fields[#fields]
  local tableToModify = self:getVariable(expression.Value)

  -- Traverse the fields to find the table to modify
  for index = 1, #fields - 1 do
    local fieldName = fields[index]
    local fieldType = type(tableToModify[fieldName])
    if fieldType ~= "table" then
      return error("Expected a table, got " .. fieldType)
    end
    tableToModify = tableToModify[fieldName]
  end
  -- Assign the new function to the last field in the table
  tableToModify[lastField] = newFunction
end

-----------------// Variable Declaration and Assignment \\-----------------

-- LocalVariableAssignment: { Variables: {}, Expressions: {} }
function ASTNodesFunctionality:LocalVariableAssignment(node)
  local expressionsResults, amountOfValues = self:executeExpressionNodes(node.Expressions)
  local variables = node.Variables

  for index = 1, amountOfValues do
    local expressionResult = expressionsResults[index]
    local variable = variables[index]
    -- If there are more expressions results than variables, just break
    if not variable then break end
    local variableName = variable

    self:registerVariable(variableName, expressionResult)
  end

  -- Register variables that dont have assigned values yet.
  for index = amountOfValues + 1, #variables do
    local variable = variables[index]
    local variableName = variable

    self:registerVariable(variableName, nil)
  end
end

-- VariableAssignment: { Variables: {}, Expressions: {} }
function ASTNodesFunctionality:VariableAssignment(node)
  local expressionsResults, amountOfValues = self:executeExpressionNodes(node.Expressions)
  local variables = node.Variables

  for index = 1, amountOfValues do
    local expressionNode = expressionsResults[index]
    local variableNode = variables[index]
    -- If there are more expressions results than variables, just break
    if not variableNode then break end

    local expressionNodeValue = variableNode
    if expressionNodeValue.TYPE == "Variable" then
      -- If the variable is an identifier, just change the variable
      self:changeVariable(expressionNodeValue.Value, expressionNode)
    elseif expressionNodeValue.TYPE == "Index" then
      -- Instead of doing self:executeExpressionNode(expressionNodeValue), we do self:executeExpressionNode(expressionNodeValue.Expression)
      -- and self:executeExpressionNode(expressionNodeValue.Index) separately to set the table and index variables.
      local expression = self:executeExpressionNode(expressionNodeValue.Expression)
      local index = self:executeExpressionNode(expressionNodeValue.Index)
      expression[index] = expressionNode
    else
      return error("Unexpected expression type: " .. expressionNodeValue.TYPE)
    end
  end

  -- Assign nil to variables that don't have assigned values yet.
  for index = amountOfValues + 1, #variables do
    local variableNode = variables[index]
    local variableNodeValue = variableNode.Value
    if variableNodeValue.TYPE == "Identifier" then
      -- If the variable is an identifier, just change the variable
      self:changeVariable(variableNodeValue.Value, nil)
    elseif variableNodeValue.TYPE == "Index" then
      -- Instead of doing self:executeExpressionNode(variableNodeValue), we do self:executeExpressionNode(variableNodeValue.Expression)
      -- and self:executeExpressionNode(variableNodeValue.Index) separately to set the table and index variables.
      local expression = self:executeExpressionNode(variableNodeValue.Expression)
      local index = self:executeExpressionNode(variableNodeValue.Index)
      expression[index] = nil
    else
      return error("Unexpected expression type: " .. tostring(variableNodeValue.TYPE))
    end
  end
end

-----------------// Function calls \\-----------------

-- FunctionCall: { Expression: {}, Arguments: {}, ExpectedReturnValueCount: 0 }
function ASTNodesFunctionality:FunctionCall(node)
  local expression = node.Expression
  local arguments = node.Arguments
  local expectedReturnValueCount = node.ExpectedReturnValueCount or 0

  local expressionResult = self:executeExpressionNode(expression)
  if type(expressionResult) ~= "function" then
    error("attempt to call a " .. type(expressionResult) .. " value")
    return
  end

  local evaluatedArguments, evaluatedArgumentAmount = self:executeExpressionNodes(arguments)
  return expressionResult(customUnpack(evaluatedArguments, evaluatedArgumentAmount))
end

-- MethodCall: { Expression: {}, Arguments: {} }
function ASTNodesFunctionality:MethodCall(node)
  local expression = node.Expression
  local arguments = node.Arguments

  -- All method calls are just functions calls, the only difference is that they're stored in tables
  -- and the first argument is the table (self) itself. So we just add the table to the arguments list.
  -- So, The expression inside node.Expression always must be "Index" type.

  local parentTable = self:executeExpressionNode(expression.Expression)
  local parentTableType = type(parentTable)

  -- Check parent table type before indexing first
  if parentTableType ~= "table" and parentTableType ~= "string" and parentTableType ~= "userdata" then
    return error("attempt to index variable (a " .. parentTableType .. " value)")
  end

  local methodName = self:executeExpressionNode(expression.Index)
  local methodNameType = type(methodName)

  -- Then check method name type
  if not methodNameType then
    return error("attempt to index variable with " .. methodNameType)
  end

  local method = parentTable[methodName]
  local methodType = type(method)
  if methodType ~= "function" and methodType ~= "table" and methodType ~= "userdata" then
    return error("attempt to call a " .. methodType .. " value")
  end

  local evaluatedArguments, evaluatedArgumentAmount = self:executeExpressionNodes(arguments)

  -- Pass "self" and the rest of the arguments to the method
  return method(parentTable, customUnpack(evaluatedArguments, evaluatedArgumentAmount))
end

-----------------// For statements \\-----------------

-- GenericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
function ASTNodesFunctionality:GenericFor(node)
  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local flags = self.flags

  self:pushScope()
  -- }

  -- [Body] {
  -- The expressions after the iterator function are optional, so we need to check if they exist
  -- and set the variables accordingly.
  -- Here's the syntax of the generic for loop:
  -- for <varList> in <iteratorFunction> [[, <iteratorTable>]? [, <iteratorControlVar>]?] do <codeBlock> end
  local iteratorFunction, iteratorTable, iteratorControlVar = self:executeExpressionNode(expressions[1])
  if expressions[2] then iteratorTable = self:executeExpressionNode(expressions[2])
  end
  if expressions[3] then iteratorControlVar = self:executeExpressionNode(expressions[3])
  end

  while true do
    -- [Loop prologue] {
    local iteratorValues = {iteratorFunction(iteratorTable, iteratorControlVar)}
    iteratorControlVar = iteratorValues[1]
    if iteratorControlVar == nil then
      -- It's the natural end of the loop, so we break.
      break
    end
    -- Set the iterator variables to the values returned by the iterator function.
    for index, iteratorVariable in ipairs(iteratorVariables) do
      self:registerVariable(iteratorVariable, iteratorValues[index])
    end
    -- }

    -- [Loop body] {
    self:executeNodes(codeBlock)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeCodeBlock",
    -- so we don't need to handle it here
    flags.continueFlag = false

    if flags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      flags.breakFlag = false
      break
    elseif flags.returnFlag then
      -- Return flags is being handled in "executeCodeBlock", we just need to break,
      -- so it won't make the loop continue.
      break
    end
    -- }
  end
  -- }

  -- [Epilogue] {
  self:popScope()
  -- }
end

-- NumericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
function ASTNodesFunctionality:NumericFor(node)
  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local iteratorVariable = node.IteratorVariables[1]
  local expressions = node.Expressions

  self:pushScope()
  local flags = self.flags
  -- }

  -- [Body] {
  -- Take required iteratorStart, iteratorEnd and optional iteratorStep values from the expressions
  -- Here's the syntax of the numeric for loop:
  -- for <iteratorControlVar> = <iteratorStart>, <iteratorEnd> [, <iteratorStep>]? do <codeBlock> end
  local iteratorStart = self:executeExpressionNode(expressions[1])
  local iteratorEnd = self:executeExpressionNode(expressions[2])
  local iteratorStep = (expressions[3] and self:executeExpressionNode(expressions[3])) or 1

  for iteratorControlVar = iteratorStart, iteratorEnd, iteratorStep do
    -- [Loop prologue] {
    self:registerVariable(iteratorVariable, iteratorControlVar)
    -- }

    -- [Loop body] {
    self:executeNodes(codeBlock)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeCodeBlock",
    -- so we don't need to handle it here
    flags.continueFlag = false

    if flags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      flags.breakFlag = false
      break
    elseif flags.returnFlag then
      -- Return flags is being handled in "executeCodeBlock", we just need to break,
      -- so it won't make the loop continue.
      break
    end
    -- }
  end
  -- }

  -- [Epilogue] {
  self:popScope()
  -- }
end

-----------------// General statements \\-----------------

-- DoBlock: { CodeBlock: {} }
function ASTNodesFunctionality:DoBlock(node)
  local codeBlock = node.CodeBlock

  self:executeCodeBlock(codeBlock, false)
end

-- IfStatement: { Condition: {}, CodeBlock: {}, ElseIfs: {}, Else: {} }
function ASTNodesFunctionality:IfStatement(node)
  local codeBlock = node.CodeBlock
  local condition = node.Condition
  local elseIfs = node.ElseIfs
  local elseBlock = (node.Else and node.Else.CodeBlock)

  -- If the main condition is true, execute the code block, and return.
  if self:executeExpressionNode(condition) then
    self:executeCodeBlock(codeBlock, false)
    return
  end

  -- If we're here, the condition was false, so we check the else-if conditions
  for index, elseIf in ipairs(elseIfs) do
    local elseIfCondition = elseIf.Condition
    local elseIfCodeBlock = elseIf.CodeBlock
    -- If the else-if condition is true, execute the code block, and return.
    if self:executeExpressionNode(elseIfCondition) then
      self:executeCodeBlock(elseIfCodeBlock, false)
      return
    end
  end

  -- If all previous conditions were false, execute the else block if it exists.
  if elseBlock then
    self:executeCodeBlock(elseBlock, false)
    return
  end
end

-- WhileLoop: { Expression: {}, CodeBlock: {} }
function ASTNodesFunctionality:WhileLoop(node)
  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local expression = node.Expression
  local flags = self.flags

  self:pushScope()
  -- }

  -- [Body] {
  while self:executeExpressionNode(expression) do
    -- [Loop body] {
    self:executeCodeBlock(codeBlock, false)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeCodeBlock",
    -- so we don't need to handle it here
    flags.continueFlag = false

    if flags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      flags.breakFlag = false
      break
    elseif flags.returnFlag then
      -- Return flags is being handled in "executeCodeBlock", we just need to break,
      -- so it won't make the loop continue.
      break
    end
    -- }
  end
  -- }

  -- [Epilogue] {
  self:popScope()
  -- }
end

-- UntilLoop: { Statement: {}, CodeBlock: {} }
function ASTNodesFunctionality:UntilLoop(node)
  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local statement = node.Statement
  local flags = self.flags

  self:pushScope()
  -- }

  -- [Body] {
  repeat
    -- [Loop body] {
    self:executeCodeBlock(codeBlock, false)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeCodeBlock",
    -- so we don't need to handle it here
    flags.continueFlag = false

    if flags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      flags.breakFlag = false
      break
    elseif flags.returnFlag then
      -- Return flags is being handled in "executeCodeBlock", we just need to break,
      -- so it won't make the loop continue.
      break
    end
    -- }
  until self:executeExpressionNode(statement)
  -- }

  -- [Epilogue] {
  self:popScope()
  -- }
end

return ASTNodesFunctionality