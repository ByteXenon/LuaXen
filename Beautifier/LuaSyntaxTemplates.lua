--[[
  Name: LuaSyntaxTemplates.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

local function stringFormat(str, formatTb)
  str = str:gsub("{([\1-\124\126-\255]+)}", function(formatValue)
    local foundFormatValue = formatTb[formatValue]
    if foundFormatValue then return foundFormatValue end
    return "" -- formatValue
  end)
  return str
end

local stringTemplates = {
  Identifier = "{codeBlockIndentation}{value}",
  String = "{codeBlockIndentation}\"{value}\"",
  Number = "{codeBlockIndentation}{value}",
  Index = "{expression}.{index}",

  Operator = "{leftExpression} {value} {rightExpression}",
  UnaryOperator = "{value} {operand}",

  NumericFor = "{codeBlockIndentation}for {iteratorVariables} = {expressions} do{codeBlock}{postCodeBlockIndentation}end",
  GenericFor = "{codeBlockIndentation}for {iteratorVariables} in {expression} do{codeBlock}{postCodeBlockIndentation}end",
  LocalVariable = "{codeBlockIndentation}local {variables} = {expressions}",
  VariableAssignment = "{codeBlockIndentation}{variables} = {expressions}",
  WhileLoop = "{codeBlockIndentation}while {expression} do{codeBlock}{postCodeBlockIndentation}end",
  
  IfStatement = "{codeBlockIndentation}if {condition} then{codeBlock}{postCodeBlockIndentation}{elseIfStatement}{elseStatement}{codeBlockIndentation}end",
  ElseIfStatement = "{codeBlockIndentation}elseif {condition} then{codeBlock}",
  ElseStatement = "{codeBlockIndentation}else {codeBlock}",

  Repeat = "{codeBlockIndentation}repeat{codeBlock}{postCodeBlockIndentation}until {expression}",
  Return = "{codeBlockIndentation}return {expressions}",
  Break = "{codeBlockIndentation}break",
  Do = "{codeBlockIndentation}do{codeBlock}{postCodeBlockIndentation}end",
  Continue = "{codeBlockIndentation}continue",

  Table = "\{{tableElements}\}",
  TableElement = "{indentation}[{key}] = {expression},",

  Function = "{codeBlockIndentation}function({arguments}){codeBlock}{postCodeBlockIndentation}end",
  -- FunctionCall = "{codeBlockIndentation}{expression}({parameters})"
}

functionTemplates = {
  FunctionCall = function(self, node, isInCodeBlock, formatTable)
    local standardTemplate = "{codeBlockIndentation}{expression}({parameters})"
    local templateWithParentheses = "{codeBlockIndentation}({expression})({parameters})"

    local expressionType = node.Expression and node.Expression.TYPE
    if expressionType ~= "Identifier" and expressionType ~= "Index" then
      return stringFormat(templateWithParentheses, formatTable)
    end
    return stringFormat(standardTemplate, formatTable)
  end,
  Index = function(self, node, isInCodeBlock, formatTable)
    local expression, index = node.Expression, node.Index
    if index.TYPE == "String" and index.Value:match("^[%a_].*") then
      return self:processNode(expression) .. "." .. index.Value
    end
    return self:processNode(expression) .. "[" .. self:processNode(index) .. "]"
  end,
  IfStatement = function(self, node, isInCodeBlock, formatTable)
    local currentIndentation = self:addSpaces()

    local elseIfsString = ""
    for i,v in pairs(node.ElseIfs) do
      local codeBlockString = self:processCodeBlock(v.CodeBlock, 1)
      local postCodeBlockIndentation = (codeBlockString == " " and "\n") or ""

      elseIfsString = elseIfsString .. currentIndentation .. "elseif " .. self:processNode(v.Condition) .. " then " .. codeBlockString .. postCodeBlockIndentation
    end
    local elseString = ""
    if node.Else.TYPE then
      local codeBlockString = self:processCodeBlock(node.Else.CodeBlock, 1)
      elseString = currentIndentation .. "else " .. ((codeBlockString == " " and "\n") or codeBlockString)
    end

    local codeBlockString = self:processCodeBlock(node.CodeBlock, 1)
    local postCodeBlockIndentation = (codeBlockString == " " and "\n") or ""
    return currentIndentation .. "if " .. self:processNode(node.Condition) .. " then " .. codeBlockString .. postCodeBlockIndentation .. elseIfsString .. elseString .. currentIndentation .. "end" 
  end,
  Table = function(self, node, isInCodeBlock, formatTable)
    local oldIndentation = self:addSpaces()
    self:increaseIndentation(1)

    local currentIndentation = self:addSpaces()
    local elementsStr = ""
    for _, node in ipairs(node.Elements) do
      elementsStr = elementsStr .. "\n" .. currentIndentation .. "[" .. self:processNode(node.Key) .. "]" .. " = " .. self:processNode(node.Value) .. ","
    end
    if elementsStr ~= "" then elementsStr = elementsStr .. "\n"..oldIndentation end

    self:decreaseIndentation(1)
    return "{" .. elementsStr .. "}"
  end
}

return {
  StringTemplates = stringTemplates,
  FunctionTemplates = functionTemplates
}