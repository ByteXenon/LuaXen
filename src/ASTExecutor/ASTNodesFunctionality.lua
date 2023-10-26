--[[
  Name: ASTNodesFunctionality.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ASTNodesFunctionality")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local insert = table.insert
local tableLen = Helpers.TableLen
local stringifyTable = Helpers.StringifyTable

--* ASTNodesFunctionality *--
local ASTNodesFunctionality = {}
function ASTNodesFunctionality:new(ASTExecutor)
  local ASTNodesFunctionalityInstance = ASTExecutor

  function ASTNodesFunctionalityInstance:executeNode(node, isInCodeBlock)
    local nodeType = node.TYPE
    if nodeType == "Expression" then
      node = node.Value
      nodeType = node.TYPE
    end
    if self[nodeType] then
      return self[nodeType](self, node, isInCodeBlock)
    end

    error("Invalid node: " .. stringifyTable(node))
  end
  function ASTNodesFunctionalityInstance:executeNodes(nodes, isInCodeBlock)
    local returnValues = {}
    local returnValuesIndex = 1
    for index, node in ipairs(nodes) do
      local nodeReturnValues = {self:executeNode(node, isInCodeBlock)}
      for _, nodeReturnValue in ipairs(nodeReturnValues or {}) do
        returnValues[returnValuesIndex] = nodeReturnValue
        returnValuesIndex = returnValuesIndex + 1
      end
    end

    return returnValues
  end

  function ASTNodesFunctionalityInstance:Number(node)   return tonumber(node.Value) end
  function ASTNodesFunctionalityInstance:String(node)   return node.Value end
  function ASTNodesFunctionalityInstance:Constant(node)
    local nodeValue = node.Value
    if nodeValue == "..." then
      return unpack((self.varArg or {}))
    elseif nodeValue == "true" or nodeValue == "false" then
      return nodeValue == "true"
    end
    return nil
  end
  function ASTNodesFunctionalityInstance:Identifier(node)
    local nodeValue = node.Value
    local localVariable = self.locals[nodeValue]
    if localVariable then
      return localVariable.Value
    end
    return self.env[nodeValue]
  end
  function ASTNodesFunctionalityInstance:UnaryOperator(node)
    local nodeValue = node.Value

    local operand = self:executeNode(node.Operand)
    if     nodeValue == "not" then return not operand
    elseif nodeValue == "#"   then return #   operand
    elseif nodeValue == "-"   then return -   operand
    end
  end
  function ASTNodesFunctionalityInstance:Operator(node)
    local nodeValue = node.Value

    local left = self:executeNode(node.Left)
    local right = self:executeNode(node.Right)

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
  end
  function ASTNodesFunctionalityInstance:FunctionCall(node, isInCodeBlock)
    local expression = self:executeNode(node.Expression)
    local parameters = self:executeNodes(node.Arguments)
    local returnValues = {expression(unpack(parameters))}
    if isInCodeBlock then return end

    return unpack(returnValues)
  end
  function ASTNodesFunctionalityInstance:Index(node, isInCodeBlock)
    local expression = (node.Expression.TYPE and self:executeNode(node.Expression)) or node.Expression
    local index = (node.Index.TYPE and self:executeNode(node.Index)) or node.Index
    return expression[index]
  end
  function ASTNodesFunctionalityInstance:Function(node, isInCodeBlock)
    local newFunction = (function(...)
      local parameters = node.Parameters
      local givenArguments = {...}

      local oldLocals = self:copyLocals()
      local oldVarArg = self.varArg

      for index, paramName in pairs(parameters) do
        if paramName == "..." then
          local varArgTb = {select(index, unpack(givenArguments))}
          self.varArg = varArgTb
          break
        end

        self:setLocalVariable(paramName, givenArguments[index])
      end
      local returnValues = {self:executeCodeBlock(node.CodeBlock)}

      self.locals = oldLocals
      self.varArg = oldVarArg
      return unpack(returnValues)
    end)

    return newFunction
  end
  function ASTNodesFunctionalityInstance:FunctionDeclaration(node, isInCodeBlock)
    local fields = node.Fields
    local accessedTable = (self.locals[fields[1]] and self.locals[fields[1]].Value) or self.env[fields[1]]
    for index = 2, #fields - 1 do
      accessedTable = accessedTable[fields[index]]
    end
    local newFunction = self:Function(node, isInCodeBlock)
    accessedTable[fields[#fields]] = newFunction
  end
  function ASTNodesFunctionalityInstance:Table(node, isInCodeBlock)
    local newTable = {}
    for _, element in ipairs(node.Elements) do
      local key = self:executeNode(element.Key)
      local value = self:executeNode(element.Value)

      newTable[key] = value
    end
    return newTable
  end
  function ASTNodesFunctionalityInstance:LocalVariable(node, isInCodeBlock)
    local variables = node.Variables
    local expressions = self:executeNodes(node.Expressions)

    for index, variable in ipairs(variables) do
      self:setLocalVariable(variable.Value, expressions[index])
    end
  end
  function ASTNodesFunctionalityInstance:LocalFunction(node, isInCodeBlock)
    self:setLocalVariable(node.Name, self:Function(node))
  end
  function ASTNodesFunctionalityInstance:VariableAssignment(node, isInCodeBlock)
    local locals = self.locals
    local variables = node.Variables
    local expressions = self:executeNodes(node.Expressions)

    for index, variable in ipairs(variables) do
      local variableValue = variable.Value
      if locals[variableValue] ~= nil then
        self:setLocalVariable(variableValue, expressions[index])
      else
        self.env[variableValue] = expressions[index]
      end
    end
  end
  function ASTNodesFunctionalityInstance:IfStatement(node, isInCodeBlock)
    local condition = self:executeNode(node.Condition)
    if condition then return self:executeCodeBlock(node.CodeBlock) end
    for index, elseIfStatement in ipairs(node.ElseIfs) do
      local condition = self:executeNode(elseIfStatement.Condition)
      if condition then return self:executeCodeBlock(elseIfStatement.CodeBlock) end
    end

    return self:executeCodeBlock(node.Else.CodeBlock or {})
  end
  function ASTNodesFunctionalityInstance:WhileLoop(node, isInCodeBlock)
    local expression = node.Expression
    local codeBlock = node.CodeBlock

    while self:executeNode(expression) do
      self:executeCodeBlock(codeBlock)
    end
  end
  function ASTNodesFunctionalityInstance:NumericFor(node, isInCodeBlock)
    local iteratorVar = node.IteratorVariables[1]
    local expressions = node.Expressions
    local codeBlock = node.CodeBlock
    local oldLocals = self:copyLocals()

    local lowLimit = self:executeNode(expressions[1])
    local upLimit = self:executeNode(expressions[2])
    local step = (expressions[3] and self:executeNode(expressions[3])) or 1

    for index = lowLimit, upLimit, step do
      self:setLocalVariable(iteratorVar, index)
      self:executeCodeBlock(codeBlock)
    end

    self.locals = oldLocals
  end
  function ASTNodesFunctionalityInstance:GenericFor(node, isInCodeBlock)
    -- Save old variables
    local oldLocals = self:copyLocals()
    local iteratorVars = node.IteratorVariables

    local expressionReturnValues = {self:executeNode(node.Expression)}
    for index, value in unpack(expressionReturnValues) do
      self:setLocalVariable(iteratorVars[1], index)
      if iteratorVars[2] then
        self:setLocalVariable(iteratorVars[2], value)
      end
      self:executeCodeBlock(node.CodeBlock)
    end

    -- Restore old local variables
    self.locals = oldLocals
  end
  function ASTNodesFunctionalityInstance:DoBlock(node, isInCodeBlock)
    local oldLocals = self:copyLocals()
    self:executeCodeBlock(node.CodeBlock)
    self.locals = oldLocals
  end
  function ASTNodesFunctionalityInstance:ReturnStatement(node, isInCodeBlock)
    self.returnValues = self:executeNodes(node.Expressions)
  end

  return ASTNodesFunctionalityInstance
end

return ASTNodesFunctionality