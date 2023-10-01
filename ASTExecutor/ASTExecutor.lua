--[[
  Name: ASTExecutor.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ASTExecutor")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local insert = table.insert
local tableLen = Helpers.TableLen

local ASTExecutor = {}
function ASTExecutor:new(AST, varArg)
  local ASTExecutorInstance = {}
  -- TODO: Add LuaState support
  ASTExecutorInstance.ast = AST
  ASTExecutorInstance.locals = {}
  ASTExecutorInstance.returnValues = nil
  ASTExecutorInstance.varArg = (varArg or {})

  function ASTExecutorInstance:setLocalVariable(localName, localValue)
    local locals = self.locals
    
    local localVariable = locals[localName]
    if not localVariable then
      localVariable = {}
      locals[localName] = localVariable
    end
    localVariable.Value = localValue
    return localVariable
  end
  function ASTExecutorInstance:getLocalValue(localName)
    local localVarible = self.locals[localName]
    if not localVariable then return end
    return localVarible.Value
  end

  function ASTExecutorInstance:getLocalVariablesValues(locals)
    local values = {}
    for _, localVariableName in ipairs(locals) do
      values[localVariableName] = self:getLocalValue(localVariableName)
    end
    return values
  end
  function ASTExecutorInstance:setLocalsValues(values)
    for localName, localTable in pairs(values) do
      self:setLocalVariable(localName, localTable.Value)
    end
  end
  function ASTExecutorInstance:copyLocals()
    local locals = {}
    for localName, localTable in pairs(self.locals) do
      locals[localName] = localTable
    end
    return locals
  end
  function ASTExecutorInstance:isolateLocalsInFunction(func, ...)
    local oldLocals = self:copyLocals()
    func(...)
    self.locals = oldLocals
  end

  function ASTExecutorInstance:executeExpression(node)
    local nodeType = node.TYPE
    if nodeType == "Identifier" then
      local nodeValue = node.Value
      local localVariable = self.locals[nodeValue]
      return (not localVariable and getfenv()[nodeValue]) or (localVariable or {}).Value
    elseif nodeType == "FunctionCall" then
      local expression = self:executeExpression(node.Expression)
      local parameters = self:executeExpressions(node.Parameters)
      local returnValues = {expression(unpack(parameters))}
      return unpack(returnValues)
    elseif nodeType == "Constant" then
      local nodeValue = node.Value
      return nodeValue 
    elseif nodeType == "Number" then
      return tonumber(node.Value)
    elseif nodeType == "String" then
      return node.Value
    elseif nodeType == "UnaryOperator" then
      local nodeValue = node.Value

      local operand = self:executeExpression(node.Operand)
      if     nodeValue == "not" then return not operand
      elseif nodeValue == "#"   then return #   operand
      elseif nodeValue == "-"   then return -   operand
      end
    elseif nodeType == "Operator" then
      local nodeValue = node.Value

      local left = self:executeExpression(node.Left)
      local right = self:executeExpression(node.Right)
      
      if     nodeValue == "and" then return left and right
      elseif nodeValue == "or"  then return left or  right
      elseif nodeValue == ".."  then return left ..  right
      elseif nodeValue == "=="  then return left ==  right
      elseif nodeValue == "~="  then return left ~=  right
      elseif nodeValue == ">="  then return left >=  right
      elseif nodeValue == "<="  then return left <=  right
      elseif nodeValue == "^"   then return left ^   right
      elseif nodeValue == "%"   then return left %   right
      elseif nodeValue == "/"   then return left /   right
      elseif nodeValue == "*"   then return left *   right
      elseif nodeValue == "+"   then return left +   right
      elseif nodeValue == "-"   then return left -   right
      end
    elseif nodeType == "Index" then
      local expression = (node.Expression.TYPE and self:executeExpression(node.Expression)) or node.Expression
      local index = (node.Index.TYPE and self:executeExpression(node.Index)) or node.Index
      return expression[index]
    elseif nodeType == "Function" then
      return (function(...)
        local parameters = node.Parameters
        local givenArguments = {...}
        local oldLocals = self:copyLocals()
        
        for index, paramName in pairs(parameters) do
          if paramName == "..." then
            local varArgTb = {}
            while givenArguments[index] do
              insert(varArgTb, givenArguments[index])
              index = index + 1
            end
          end
          self:setLocalVariable(paramName, givenArguments[index])
        end
        local returnValues = {self:executeCodeBlock(node.CodeBlock)}

        self.locals = oldLocals
        return unpack(returnValues)
      end)
    elseif nodeType == "Table" then
      local newTable = {}
      for _, element in ipairs(node.Elements) do
        local key = self:executeExpression(element.Key)
        local value = self:executeExpression(element.Value)
        
        newTable[key] = value
      end
      return newTable
    else
      Helpers.PrintTable(node)
    end

    return node.Value
  end
  function ASTExecutorInstance:executeExpressions(nodeList)
    local expressions = {}
    for _, node in ipairs(nodeList) do
      insert(expressions, self:executeExpression(node) or {})
    end
    return expressions
  end
  function ASTExecutorInstance:executeNode(node)
    local nodeType = node.TYPE
    if nodeType == "FunctionCall" then
      local expression = self:executeExpression(node.Expression)
      local parameters = self:executeExpressions(node.Parameters)
  
      expression(unpack(parameters))
    elseif nodeType == "LocalVariable" then
      local variables = node.Variables
      local expressions = self:executeExpressions(node.Expressions)

      for index, variable in ipairs(variables) do
        self:setLocalVariable(variable.Value, expressions[index])
      end
    elseif nodeType == "LocalFunction" then
      self:setLocalVariable(node.Name, function(...)
        local arguments = node.Arguments
        local givenArguments = {...}
        local oldLocals = self:copyLocals()
        
        for index, argumentTable in pairs(arguments) do
          self:setLocalVariable(argumentTable, givenArguments[index])
        end
        local returnValues = {self:executeCodeBlock(node.CodeBlock)}
        
        self.locals = oldLocals
        return unpack(returnValues)
      end)
    elseif nodeType == "Function" then

    elseif nodeType == "VariableAssignment" then
      local locals = self.locals
      local variables = node.Variables
      local expressions = self:executeExpressions(node.Expressions)

      for index, variable in ipairs(variables) do
        local variableValue = variable.Value
        if locals[variableValue] ~= nil then
          self:setLocalVariable(variableValue, expressions[index])
        else
          getfenv()[variableValue] = expressions[index]
        end
      end
    elseif nodeType == "IfStatement" then
      local condition = self:executeExpression(node.Condition)
      if condition then return self:executeCodeBlock(node.CodeBlock) end
      for index, elseIfStatement in ipairs(node.ElseIfs) do
        local condition = self:executeExpression(elseIfStatement.Condition)
        if condition then return self:executeCodeBlock(elseIfStatement.CodeBlock) end
      end
      return self:executeCodeBlock(node.Else.CodeBlock or {})
    elseif nodeType == "WhileLoop" then
      while self:executeExpression(node.Expression) do
        self:executeCodeBlock(node.CodeBlock)
      end
    elseif nodeType == "NumericFor" then
      local iteratorVar = node.IteratorVariables[1]
      local expressions = node.Expressions
      local oldLocals = self:copyLocals()

      local lowLimit = self:executeExpression(expressions[1])
      local upLimit = self:executeExpression(expressions[2])
      local step = (expressions[3] and self:executeExpression(expressions[3])) or 1

      for index = lowLimit, upLimit, step do
        self:setLocalVariable(iteratorVar, index)
        self:executeCodeBlock(node.CodeBlock)
      end
      
      self.locals = oldLocals
    elseif nodeType == "GenericFor" then
      -- Save old variables
      local oldLocals = self:copyLocals()
      local iteratorVars = node.IteratorVariables

      local func, tb = self:executeExpression(node.Expression)
      local tableLength = tableLen(tb)

      local index;
      while true do
        local returnValues = {next(tb, index)}
        for idx, var in ipairs(iteratorVars) do
          self:setLocalVariable(var, returnValues[idx])
        end
        self:executeCodeBlock(node.CodeBlock)

        index = (index or 0) + 1
        if index >= tableLength then break end
      end
      
      -- Restore old local variables
      self.locals = oldLocals
    elseif nodeType == "Do" then
      self:isolateLocalsInFunction(self.executeCodeBlock, self, node.CodeBlock)
    elseif nodeType == "Return" then
      self.returnValues = self:executeExpressions(node.Expressions)
    else
      Helpers.PrintTable(node)
    end
  end
  function ASTExecutorInstance:executeCodeBlock(nodeList, saveLocals)
    local oldLocals = self:copyLocals()
    for _, node in ipairs(nodeList) do
      self:executeNode(node)
      local returnValues = self.returnValues
      if returnValues then
        self.returnValues = nil
        if not saveLocals then self.locals = oldLocals end
        return unpack(returnValues)
      end
    end

    if not saveLocals then self.locals = oldLocals end
  end
  function ASTExecutorInstance:execute()
    return self:executeCodeBlock(self.ast)
  end

  return ASTExecutorInstance
end

return ASTExecutor