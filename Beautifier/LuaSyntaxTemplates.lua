--[[
  Name: LuaSyntaxTemplates.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--[[ NOTE:

  "postCodeBlockIndentation" (format name to change) means an optional indentation which may be or may be not present
  depending on total number of code block elements, if there's more than 1 element in a code block, it will
  include a new line character ("\n") and current indentation, if there's no elements in the code block,
  it will return an empty string instead.

--]]

local stringTemplates = {
  Identifier = "{codeBlockIndentation}{value}",
  String = "{codeBlockIndentation}\"{value}\"",
  Number = "{codeBlockIndentation}{value}",
  
  Operator = "{leftExpression} {value} {rightExpression}",
  UnaryOperator = "{value} {operand}",

  NumericFor = "{codeBlockIndentation}for {iteratorVariables} = {expressions} do{codeBlock}{postCodeBlockIndentation}end",
  GenericFor = "{codeBlockIndentation}for {iteratorVariables} in {expression} do{codeBlock}{postCodeBlockIndentation}end",
  LocalVariable = "{codeBlockIndentation}local {variables} = {expressions}",
  VariableAssignment = "{codeBlockIndentation}{variables} = {expressions}",
  WhileLoop = "{codeBlockIndentation}while {expression} do{codeBlock}{postCodeBlockIndentation}end",
  
  IfStatement = "{codeBlockIndentation}if {expression} then{codeBlock}",
  ElseIfStatement = "{codeBlockIndentation}elseif {expression} then{codeBlock}",
  ElseStatement = "{codeBlockIndentation}else {codeBlock}",

  Repeat = "{codeBlockIndentation}repeat{codeBlock}{postCodeBlockIndentation}until {expression}",
  Return = "{codeBlockIndentation}return {expressions}",
  Break = "{codeBlockIndentation}break",
  Do = "{codeBlockIndentation}do{codeBlock}{postCodeBlockIndentation}end",
  Continue = "{codeBlockIndentation}continue",

  Table = "\{{tableElements}\}",
  TableElement = "{indentation}[{key}] = {expression},",

  Function = "{codeBlockIndentation}function({arguments}){codeBlock}{postCodeBlockIndentation}end",
  FunctionCall = "{codeBlockIndentation}{expression}({arguments})"
}

return {
  StringTemplates = stringTemplates,
}