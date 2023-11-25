--[[
  Name: NodeSpecs.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This file contains the specifications for the AST nodes.
    It is mainly used for traversing the AST.
--]]

--[[
  Types of Fields:
    - String: A string
    - StringList: A list of strings
    - Node: A node
    - NodeList: A list of nodes
    - OptionalNode: A node or nil
    - TableElementList: A list of table elements
    - Value: A value
--]]

local NodeSpecs = {
  --/// Expression nodes \\\--
  Identifier          = { Value   = "Value"                                         },
  Constant            = { Value   = "Value"                                         },
  Number              = { Value   = "Value"                                         },
  String              = { Value   = "Value"                                         },

  Operator            = { Left    = "Node", Right    = "Node",  Operator = "String" },
  UnaryOperator       = { Operand = "Node", Operator = "String"                     },
  Expression          = { Value   = "Node"                                          },

  FunctionCall        = { Expression  = "Node", Arguments   = "NodeList"            },
  MethodCall          = { Expression  = "Node", Arguments   = "NodeList"            },

  Index               = { Index       = "Node", Expression  = "Node"                },
  MethodIndex         = { Index       = "Node", Expression  = "Node"                },

  Table               = { Elements    = "TableElementList"                          },
  TableElement        = { Key         = "Node", Value       = "Node"                },

  --/// Statement nodes \\\--
  Function            = { Parameters  = "StringList", CodeBlock = "NodeList"                                              },
  FunctionDeclaration = { Parameters  = "StringList", CodeBlock = "NodeList", Fields  = "StringList"                      },
  MethodDeclaration   = { Parameters  = "StringList", CodeBlock = "NodeList", Fields  = "StringList"                      },
  LocalFunction       = { Parameters  = "StringList", CodeBlock = "NodeList", Name    = "String"                          },

  VariableAssignment  = { Expressions = "NodeList", Variables   = "NodeList"                                              },
  LocalVariable       = { Variables   = "NodeList", Expressions = "NodeList"                                              },
  IfStatement         = { Condition   = "Node",     CodeBlock   = "NodeList", ElseIfs = "NodeList", Else = "OptionalNode" },
  ElseIfStatement     = { Condition   = "Node",     CodeBlock   = "NodeList"                                              },
  ElseStatement       = { CodeBlock   = "NodeList"                                                                        },
  UntilLoop           = { CodeBlock   = "NodeList", Statement   = "Node"                                                  },
  DoBlock             = { CodeBlock   = "NodeList"                                                                        },
  WhileLoop           = { Expression  = "Node",     CodeBlock   = "NodeList"                                              },
  ReturnStatement     = { Expressions = "NodeList"                                                                        },

  ContinueStatement   = { },
  BreakStatement      = { },

  GenericFor          = { IteratorVariables = "StringList", Expression = "Node", CodeBlock = "NodeList" },
  NumericFor          = { IteratorVariables = "StringList", Expression = "Node", CodeBlock = "NodeList" }
}

return NodeSpecs