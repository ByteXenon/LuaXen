--[[
  Name: ASTNodesFunctionality.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This internal module provides specific functions for executing different types of AST nodes. 
    Each function corresponds to a particular type of AST node and contains the logic to execute 
    that node within the context of a Lua script. This module is exclusively utilized by the 
    ASTExecutor module to interpret and execute the AST.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ASTNodesFunctionality")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local unpack = (unpack or table.unpack)

--* ASTNodesFunctionality *--
local ASTNodesFunctionality = {}

-----------------// Flow Control \\-----------------

-- ContinueStatement: {}
function ASTNodesFunctionality:ContinueStatement(node, state)
  self.globalFlags.continueFlag = true
end

-- BreakStatement: {}
function ASTNodesFunctionality:BreakStatement(node, state)
  self.globalFlags.breakFlag = true
end

-- ReturnStatement: { Expressions: {} }
function ASTNodesFunctionality:ReturnStatement(node, state)
  local expressions = node.Expressions

  local results = self:executeNodes(expressions, state)
  self.returnValues = results
  self.globalFlags.returnFlag = true
end

-----------------// Literal and Identifier Nodes \\-----------------

-- Constant: { Value: "" }
function ASTNodesFunctionality:Constant(node, state)
  local value = node.Value
  if type(value) == "boolean" then
    return value
  elseif value == "true" or value == "false" then
    return value == "true"
  end
  return nil
end

-- Identifier: { Value: "" }
function ASTNodesFunctionality:Identifier(node, state)
  local value = node.Value
  return self:getVariable(value, state)
end

-- Number: { Value: "" }
function ASTNodesFunctionality:Number(node, state)
  return tonumber(node.Value)
end

-- String: { Value: "" }
function ASTNodesFunctionality:String(node, state)
  return tostring(node.Value)
end

-- Table: { Elements: {} }
function ASTNodesFunctionality:Table(node, state)
  local elements = node.Elements

  local newTable = {}
  for _, element in ipairs(elements) do
    local value = self:executeNode(element.Value, state)
    local index = self:executeNode(element.Key, state)
    newTable[index] = value
  end
  return newTable
end

-----------------// Table Indexing \\-----------------

-- TODO: DRY it out

-- Index: { Expression: {}, Index: {} }
function ASTNodesFunctionality:Index(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local index = node.Index
  local expression = self:executeNode(node.Expression, state)
  local expressionType = type(expression)

  -- Check expression type before indexing
  if expressionType ~= "table" and expressionType ~= "string" and expressionType ~= "userdata" then
    return error("attempt to index variable (a " .. expressionType .. " value)")
  end

  local evaluatedIndex = self:executeNode(index, state)
  if not evaluatedIndex then
    local indexType = type(evaluatedIndex)
    return error("attempt to index variable with " .. indexType)
  end

  return expression[evaluatedIndex]
end

-- MethodIndex: { Expression: {}, Index: {} }
function ASTNodesFunctionality:MethodIndex(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local index = node.Index
  local expression = self:executeNode(node.Expression, state)
  local expressionType = type(expression)

  -- Check expression type before indexing
  if expressionType ~= "table" and expressionType ~= "string" and expressionType ~= "userdata" then
    return error("attempt to index variable (a " .. expressionType .. " value)")
  end

  local evaluatedIndex = self:executeNode(index, state)
  if not evaluatedIndex then
    local indexType = type(evaluatedIndex)
    return error("attempt to index variable with " .. indexType)
  end

  return expression[evaluatedIndex]
end

-----------------// Operators \\-----------------

-- Operator: { Left: {}, Right: {}, Value: "" }
function ASTNodesFunctionality:Operator(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local operator = node.Value
  local left = self:executeNode(node.Left, state)
  local right;
  -- For optimization purposes, we only execute the right node if the operator is not "and" or "or"
  if operator ~= "and" and operator ~= "or" then
    right = self:executeNode(node.Right, state)
  end

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
    -- For optimization purposes, we only execute the right node if the left node is true
    -- Default Lua behavior is the same.
    if not left then return left end
    return left and self:executeNode(node.Right, state)
  elseif operator == "or"  then
    -- For optimization purposes, we only execute the right node if the left node is false
    -- Default Lua behavior is the same.
    if left then return left end
    return left or self:executeNode(node.Right, state)
  else
    return error("Invalid operator: " .. operator)
  end
end

-- UnaryOperator: { Operand: {}, Value: "" }
function ASTNodesFunctionality:UnaryOperator(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local operator = node.Value
  local operand = self:executeNode(node.Operand, state)

  if     operator == "-"   then return -   operand
  elseif operator == "not" then return not operand
  elseif operator == "#"   then return #   operand
  else
    return error("Invalid unary operator: " .. operator)
  end
end

-----------------// Function Definitions \\-----------------

-- Function: { Parameters: {}, CodeBlock: {} }
function ASTNodesFunctionality:Function(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local parameters = node.Parameters
  local codeBlock = node.CodeBlock

  return self:makeLuaFunction(parameters, codeBlock, state)
end

-- LocalFunction: { Name: {}, Parameters: {}, CodeBlock: {} }
function ASTNodesFunctionality:LocalFunction(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local name = node.Name
  local parameters = node.Parameters
  local codeBlock = node.CodeBlock
  local newFunction = self:makeLuaFunction(parameters, codeBlock, state)

  return self:registerVariable(name, newFunction)
end

-- FunctionDeclaration: { Fields: {}, Parameters: {}, CodeBlock: {} }
function ASTNodesFunctionality:FunctionDeclaration(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local fields = node.Fields
  local codeBlock = node.CodeBlock
  local parameters = node.Parameters
  local newFunction = self:makeLuaFunction(parameters, codeBlock, state)

  -- If the function is not in a table, just declare it
  if #fields == 1 then
    return self:changeVariable(fields[1], newFunction, state)
  end

  local lastField = fields[#fields]
  local tableToModify = self:getVariable(fields[1], state)

  -- Traverse the fields to find the table to modify
  for index = 2, #fields - 1 do
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

-- MethodDeclaration: { Fields: {}, Parameters: {}, CodeBlock: {} }
function ASTNodesFunctionality:MethodDeclaration(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local fields = node.Fields
  local codeBlock = node.CodeBlock
  local parameters = node.Parameters
  local newParameters = {"self"}

  -- Copy parameters to newParameters, starting from index 2
  for index, value in ipairs(parameters) do
    newParameters[index + 1] = value
  end

  local newFunction = self:makeLuaFunction(newParameters, codeBlock, state)

  local lastField = fields[#fields]
  local tableToModify = self:getVariable(fields[1], state)

  -- Traverse the fields to find the table to modify
  for index = 2, #fields - 1 do
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

-- LocalVariable: { Variables: {}, Expressions: {} }
function ASTNodesFunctionality:LocalVariable(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local expressionsResults = self:executeNodes(node.Expressions, state)
  local variables = node.Variables

  for index, expressionResult in ipairs(expressionsResults) do
    local variable = variables[index]
    -- If there are more expressions results than variables, just break
    if not variable then break end
    local variableName = variable.Value

    self:registerVariable(variableName, expressionResult)
  end
end

-- VariableAssignment: { Variables: {}, Expressions: {} }
function ASTNodesFunctionality:VariableAssignment(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local expressionsResults = self:executeNodes(node.Expressions, state)
  local variables = node.Variables

  for index, expressionNode in ipairs(expressionsResults) do
    local variableNode = variables[index]
    -- If there are more expressions results than variables, just break
    if not variableNode then break end

    local expressionNodeValue = variableNode.Value
    if expressionNodeValue.TYPE == "Identifier" then
      -- If the variable is an identifier, just change the variable
      self:changeVariable(expressionNodeValue.Value, expressionNode, state)
      return
    elseif expressionNodeValue.TYPE == "Index" then
      -- Instead of doing self:executeNode(expressionNodeValue), we do self:executeNode(expressionNodeValue.Expression)
      -- and self:executeNode(expressionNodeValue.Index) separately to set the table and index variables.
      local expression = self:executeNode(expressionNodeValue.Expression, state)
      local index = self:executeNode(expressionNodeValue.Index, state)
      expression[index] = expressionNode
      return
    else
      return error("Unexpected expression type: " .. expressionNodeValue.TYPE)
    end
  end
end

-----------------// Function calls \\-----------------

-- FunctionCall: { Expression: {}, Arguments: {} }
function ASTNodesFunctionality:FunctionCall(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local expression = node.Expression
  local arguments = node.Arguments

  local expressionResult = self:executeNode(expression, state)
  if type(expressionResult) ~= "function" then
    return error("attempt to call a " .. type(expressionResult) .. " value")
  end

  local evaluatedArguments = {}
  for _, argument in ipairs(arguments) do
    -- Since some nodes can return multiple values (e.g function calls/vararg),
    -- we need to unpack them
    local argumentValues = {self:executeNode(argument, state)}

    for _, value in pairs(argumentValues) do
      insert(evaluatedArguments, value)
    end
  end

  return expressionResult(unpack(evaluatedArguments))
end

-- MethodCall: { Expression: {}, Arguments: {} }
function ASTNodesFunctionality:MethodCall(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local expression = node.Expression
  local arguments = node.Arguments

  -- All method calls are just functions calls, the only difference is that they're stored in tables
  -- and the first argument is the table (self) itself. So we just add the table to the arguments list.
  -- So, The expression inside node.Expression always must be "Index" type.

  local parentTable = self:executeNode(expression.Expression, state)
  local parentTableType = type(parentTable)

  -- Check parent table type before indexing first
  if parentTableType ~= "table" and parentTableType ~= "string" and parentTableType ~= "userdata" then
    return error("attempt to index variable (a " .. parentTableType .. " value)")
  end

  local methodName = self:executeNode(expression.Index, state)
  local methodNameType = type(methodName)

  -- Then check method name type
  if not methodNameType then
    return error("attempt to index variable with " .. methodNameType)
  end
  
  local method = parentTable[methodName]
  local methodType = type(method)
  
  -- And finally check method type
  if methodType ~= "function" and methodType ~= "table" and methodType ~= "userdata" then
    return error("attempt to call a " .. methodType .. " value")
  end

  local evaluatedArguments = {}
  for index, argument in ipairs(arguments) do
    local argumentValues = {self:executeNode(argument, state)}
    for _, value in pairs(argumentValues) do
      insert(evaluatedArguments, value)
    end
  end
  
  -- Pass "self" and the rest of the arguments to the method
  return method(parentTable, unpack(evaluatedArguments))
end

-----------------// For statements \\-----------------

-- GenericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
function ASTNodesFunctionality:GenericFor(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local globalFlags = self.globalFlags

  self:pushScope()
  -- }

  -- [Body] {
  -- The expressions after the iterator function are optional, so we need to check if they exist
  -- and set the variables accordingly.
  -- Here's the syntax of the generic for loop:
  -- for <varList> in <iteratorFunction> [[, <iteratorTable>]? [, <iteratorControlVar>]?] do <codeBlock> end
  local iteratorFunction, iteratorTable, iteratorControlVar = self:executeNode(expressions[1], state)
  if expressions[2] then iteratorTable = self:executeNode(expressions[2], state)
  end
  if expressions[3] then iteratorControlVar = self:executeNode(expressions[3], state)
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
    self:executeNodes(codeBlock, state, true)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeNodes",
    -- so we don't need to handle it here
    globalFlags.continueFlag = false
    
    if globalFlags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      globalFlags.breakFlag = false
      break
    elseif globalFlags.returnFlag then
      -- Return flags is being handled in "executeNodes", we just need to break,
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
function ASTNodesFunctionality:NumericFor(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local iteratorVariable = node.IteratorVariables[1]
  local expressions = node.Expressions

  self:pushScope()
  local globalFlags = self.globalFlags
  -- }

  -- [Body] {
  -- Take required iteratorStart, iteratorEnd and optional iteratorStep values from the expressions
  -- Here's the syntax of the numeric for loop:
  -- for <iteratorControlVar> = <iteratorStart>, <iteratorEnd> [, <iteratorStep>]? do <codeBlock> end
  local iteratorStart = self:executeNode(expressions[1], state)
  local iteratorEnd = self:executeNode(expressions[2], state)
  local iteratorStep = (expressions[3] and self:executeNode(expressions[3], state)) or 1

  for iteratorControlVar = iteratorStart, iteratorEnd, iteratorStep do
    -- [Loop prologue] {
    self:registerVariable(iteratorVariable, iteratorControlVar)
    -- }

    -- [Loop body] {
    self:executeNodes(codeBlock, state, true)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeNodes",
    -- so we don't need to handle it here
    globalFlags.continueFlag = false
    
    if globalFlags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      globalFlags.breakFlag = false
      break
    elseif globalFlags.returnFlag then
      -- Return flags is being handled in "executeNodes", we just need to break,
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
function ASTNodesFunctionality:DoBlock(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local codeBlock = node.CodeBlock

  self:executeCodeBlock(codeBlock, state)
end

-- IfStatement: { Condition: {}, CodeBlock: {}, ElseIfs: {}, Else: {} }
function ASTNodesFunctionality:IfStatement(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  local codeBlock = node.CodeBlock
  local condition = node.Condition
  local elseIfs = node.ElseIfs
  local elseBlock = (node.Else and node.Else.CodeBlock) 

  -- If the main condition is true, execute the code block, and return.
  if self:executeNode(condition, state) then
    self:executeCodeBlock(codeBlock, state)
    return
  end

  -- If we're here, the condition was false, so we check the else-if conditions
  for index, elseIf in ipairs(elseIfs) do
    local elseIfCondition = elseIf.Condition
    local elseIfCodeBlock = elseIf.CodeBlock
    -- If the else-if condition is true, execute the code block, and return.
    if self:executeNode(elseIfCondition, state) then
      self:executeCodeBlock(elseIfCodeBlock, state)
      return
    end
  end

  -- If all previous conditions were false, execute the else block if it exists.
  if elseBlock then
    self:executeCodeBlock(elseBlock, state)
    return
  end
end

-- WhileLoop: { Expression: {}, CodeBlock: {} }
function ASTNodesFunctionality:WhileLoop(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local expression = node.Expression
  local globalFlags = self.globalFlags

  self:pushScope()
  -- }

  -- [Body] {
  while self:executeNode(expression, state) do
    -- [Loop body] {
    self:executeCodeBlock(codeBlock, state, true)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeNodes",
    -- so we don't need to handle it here
    globalFlags.continueFlag = false
    
    if globalFlags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      globalFlags.breakFlag = false
      break
    elseif globalFlags.returnFlag then
      -- Return flags is being handled in "executeNodes", we just need to break,
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
function ASTNodesFunctionality:UntilLoop(node, state)
  -- Set the last executed node to this node
  self.lastExecutedNode = node

  -- [Prologue] {
  local codeBlock = node.CodeBlock
  local statement = node.Statement
  local globalFlags = self.globalFlags

  self:pushScope()
  -- }

  -- [Body] {
  repeat
    -- [Loop body] {
    self:executeCodeBlock(codeBlock, state, true)
    -- }

    -- [Loop epilogue] {
    -- Always reset the continue flag, it gets handled in "executeNodes",
    -- so we don't need to handle it here
    globalFlags.continueFlag = false
    
    if globalFlags.breakFlag then
      -- Reset the break flag, so it doesn't affect other loops
      globalFlags.breakFlag = false
      break
    elseif globalFlags.returnFlag then
      -- Return flags is being handled in "executeNodes", we just need to break,
      -- so it won't make the loop continue.
      break
    end
    -- }
  until self:executeNode(statement, state)
  -- }

  -- [Epilogue] {
  self:popScope()
  -- }
end

return ASTNodesFunctionality