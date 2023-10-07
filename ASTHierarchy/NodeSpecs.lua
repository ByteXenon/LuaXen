--[[
  Name: NodeSpecs.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

local NodeSpecs = {
  Operator            = { Left        = "Node",         Right       = "Node" },
  UnaryOperator       = { Operand     = "Node" },
  FunctionCall        = { Expression  = "Node",         Parameters  = "NodeList" },
  MethodCall          = { Expression  = "Node",         Parameters  = "NodeList" },
  Identifier          = { Value       = "Value" },
  Number              = { Value       = "Value" },
  Index               = { Index       = "Node",         Expression  = "Node" },
  MethodIndex         = { Index       = "Node",         Expression  = "Node" },
  Table               = { Elements    = "NodeList" },
  TableElement        = { Key         = "Node",         Value       = "Node" },
  Function            = { Parameters  = "StringList",   CodeBlock   = "NodeList" },
  FunctionDeclaration = { Parameters  = "StringList",   CodeBlock   = "NodeList", Fields="StringList" },
  MethodDeclaration   = { Parameters  = "StringList",   CodeBlock   = "NodeList", Fields="StringList" },
  VariableAssignment  = { Expressions = "NodeList",     Variables   = "NodeList" },
  LocalFunction       = { Name        = "Node",         Parameters  = "NodeList", CodeBlock="NodeList" },
  LocalVariable       = { Variables   = "NodeList",     Expressions = "NodeList" },
  IfStatement         = { Condition   = "Node",         CodeBlock   = "NodeList", ElseIfs="NodeList", Else="OptionalNode" },
  ElseIfStatement     = { Condition   = "Node",         CodeBlock   = "NodeList" },
  ElseStatement       = { CodeBlock   = "NodeList" },
  UntilLoop           = { CodeBlock   = "NodeList",     Statement   = "OptionalNode" },
  DoBlock             = { CodeBlock   = "NodeList" },
  WhileLoop           = { Expression  = "OptionalNode", CodeBlock   = "NodeList" },
  ReturnStatement     = { Expressions = "NodeList" },
  
  ContinueStatement   = { },
  BreakStatement      = { },

  GenericFor          = { IteratorVariables="StringList", Expression="Node", CodeBlock="NodeList" },
  NumericFor          = { IteratorVariables="StringList", Expression="Node", CodeBlock="NodeList" }
}

return NodeSpecs