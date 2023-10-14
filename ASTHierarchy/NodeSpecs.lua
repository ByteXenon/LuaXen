--[[
  Name: NodeSpecs.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

local NodeSpecs = {
  Operator            = { Left        = "Node",         Right       = "Node" },
  UnaryOperator       = { Operand     = "Node" },
  FunctionCall        = { Expression  = "Node",         Arguments   = "NodeList" },
  MethodCall          = { Expression  = "Node",         Arguments   = "NodeList" },
  Identifier          = { Value       = "Value" },
  Constant            = { Value       = "Value" },
  Number              = { Value       = "Value" },
  String              = { Value       = "Value" },
  Index               = { Index       = "Node",         Expression  = "Node" },
  MethodIndex         = { Index       = "Node",         Expression  = "Node" },
  Table               = { Elements    = "TableElementList" },
  TableElement        = { Key         = "Node",         Value       = "Node" },
  
  Function            = { Parameters  = "StringList",   CodeBlock   = "NodeList" },
  FunctionDeclaration = { Parameters  = "StringList",   CodeBlock   = "NodeList", Fields  = "StringList" },
  MethodDeclaration   = { Parameters  = "StringList",   CodeBlock   = "NodeList", Fields  = "StringList" },
  LocalFunction       = { Parameters  = "StringList",   CodeBlock   = "NodeList", Name    = "String" },

  VariableAssignment  = { Expressions = "NodeList",     Variables   = "NodeList" },
  LocalVariable       = { Variables   = "NodeList",     Expressions = "NodeList" },
  IfStatement         = { Condition   = "Node",         CodeBlock   = "NodeList", ElseIfs = "NodeList", Else = "OptionalNode" },
  ElseIfStatement     = { Condition   = "Node",         CodeBlock   = "NodeList" },
  ElseStatement       = { CodeBlock   = "NodeList" },
  UntilLoop           = { CodeBlock   = "NodeList",     Statement   = "Node" },
  DoBlock             = { CodeBlock   = "NodeList" },
  WhileLoop           = { Expression  = "Node",         CodeBlock   = "NodeList" },
  ReturnStatement     = { Expressions = "NodeList" },
  
  ContinueStatement   = { },
  BreakStatement      = { },

  GenericFor          = { IteratorVariables = "StringList", Expression = "Node", CodeBlock = "NodeList" },
  NumericFor          = { IteratorVariables = "StringList", Expression = "Node", CodeBlock = "NodeList" }
}

return NodeSpecs