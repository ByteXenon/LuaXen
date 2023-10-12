--[[
  Name: NodeMethods.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/NodeMethods/NodeMethods")
local NodeMethodsFunctions = ModuleManager:loadModule("ASTHierarchy/NodeMethods/NodeMethodsFunctions")

--* NodeMethods *--
local NodeMethods = {
  Operator            = { }, UnaryOperator       = { },
  FunctionCall        = { }, MethodCall          = { },
  Identifier          = { }, Constant            = { },
  Number              = { },
  String              = { }, Index               = { },
  MethodIndex         = { }, Table               = { },
  TableElement        = { }, Function            = { },
  FunctionDeclaration = { }, MethodDeclaration   = { },
  LocalFunction       = { }, VariableAssignment  = { },
  LocalVariable       = { }, IfStatement         = { },
  ElseIfStatement     = { }, ElseStatement       = { },
  UntilLoop           = { }, DoBlock             = { },
  WhileLoop           = { }, ReturnStatement     = { },
  ContinueStatement   = { }, BreakStatement      = { },
  GenericFor          = { }, NumericFor          = { },
  AST                 = { }
}

local function createNodeMethod(nodeType, methodIndex, func)
  if nodeType == "_Default" then
    for index, nodeTypeTable in pairs(NodeMethods) do
      nodeTypeTable[methodIndex] = func 
    end
    return 
  end

  local nodeTypeTb = NodeMethods[nodeType]
  if not nodeTypeTb then
    return error(("Invalid node type: %s"):format(tostring(nodeType)))
  end

  nodeTypeTb[methodIndex] = func
end
local function createNodeMethodsFromTable(tb)
  for nodeType, nodeTypeTb in pairs(tb) do
    for methodIndex, method in pairs(nodeTypeTb) do
      createNodeMethod(nodeType, methodIndex, method)
    end
  end
  return NodeMethods
end

return createNodeMethodsFromTable(NodeMethodsFunctions)