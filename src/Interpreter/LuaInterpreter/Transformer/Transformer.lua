--[[
  Name: Transformer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--[[
  What nodes the transformer would add:
    LocalVariables, GlobalVariables, and Upvalues out of "Identifier" nodes
  What field the transformer would add:
    LocalVariables: If its a constant, or not.
    LocalVariables: Possible type by predicting the value.
    Loops: If it has a break or continue statement, for optimization.
    FunctionCalls: Number of return values
    FunctionCalls: If it is a tail call
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Transformer/Transformer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeSpecs = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/NodeSpecs")
local InternalMethods = ModuleManager:loadModule("Interpreter/LuaInterpreter/Transformer/InternalMethods")
local NodeTransformations = ModuleManager:loadModule("Interpreter/LuaInterpreter/Transformer/NodeTransformations")
local ScopeManager = ModuleManager:loadModule("Interpreter/LuaInterpreter/Transformer/ScopeManager")

--* Export library functions *--
local insert = table.insert
local remove = table.remove
local concat = table.concat

--* TransformerMethods *--
local TransformerMethods = {}

-- Traverses a list of nodes and applies field type functions to each node
function TransformerMethods:traverseNodeList(nodeList, fieldTypeFunctions)
  if not nodeList._methods then
    self:applyTransformations(nodeList)
  end

  for index, node in ipairs(nodeList) do
    if fieldTypeFunctions["Node"] then
      fieldTypeFunctions["Node"](node, index)
    end
  end
end

-- Traverses a node using standard traversal and applies field type functions to each node
function TransformerMethods:standardTraverse(node)
  local fieldTypeFunctions = {}
  fieldTypeFunctions.Node = function(node, index)
    insert(self.nodeStack, { Value = node, Index = index })
    self:standardTraverse(node)
    remove(self.nodeStack)
  end
  fieldTypeFunctions.NodeList = function(node, index)
    insert(self.nodeStack, { Value = node, Index = index })
    self:standardTraverse(node)
    remove(self.nodeStack)
  end
  
  self:traverseNode(node, fieldTypeFunctions)
end

-- Traverses a node and applies field type functions to each field
function TransformerMethods:traverseNode(node, fieldTypeFunctions)
  local nodeType = node.TYPE
  local nodeSpecs = NodeSpecs[nodeType]

  if not fieldTypeFunctions then
    return error("No field type functions for node type: " .. nodeType)
  end
  if not nodeType or nodeType == "Group" then
    -- It's either a group, or an AST (which is a group too)
    return self:traverseNodeList(node, fieldTypeFunctions)
  end

  if not node._methods then
    self:applyTransformations(node)
  end

  if nodeSpecs then
    for nodeField, fieldType in pairs(nodeSpecs) do
      if fieldTypeFunctions[fieldType] then
        if nodeField == "CodeBlock" then
          self:pushScope()
        end
        fieldTypeFunctions[fieldType](node[nodeField], nodeField)
        if nodeField == "CodeBlock" then
          self:popScope()
        end
      end
    end
  else
    return error("No node specs for node type: " .. nodeType)
  end

  return node
end

-- Applies transformations to a node by adding methods to it
function TransformerMethods:applyTransformations(node)
  local nodeType = node.TYPE

  -- We could make a proxy here, which would store methods and internal data in a metatable, and add __pairs metamethod to it,
  -- But since Lua 5.1- doesn't support the __pairs metamethod, let's use normal tables, so we would support all Lua versions.
  -- Of course we could replace the "pairs" and "ipairs" globals with custom ones, to make it support __pairs
  -- But changing globals is **strictly prohibited** in this entire project, so we won't do that.
  local methods = {}
  local _internal = {}

  local lastStackInstance = self.nodeStack[#self.nodeStack - 1]
  local parent, index
  if lastStackInstance then
    _internal.parent = lastStackInstance.Value
    _internal.index = lastStackInstance.Index
  end

  for index, value in pairs(InternalMethods) do
    -- Make a wrapper function, so we can pass the node and _internal to the function
    methods[index] = function(pseudoSelf, ...)
      return value(self, node, _internal, ...)
    end
  end

  node._methods = methods

  if NodeTransformations[nodeType] then
    NodeTransformations[nodeType](self, node)
  end
end

--////// Main (Public) //////--

-- Runs the transformation process on the AST
function TransformerMethods:run()
  self:standardTraverse(self.ast)

  return self.ast
end

--* Transformer *--
local Transformer = {}

-- Creates a new instance of the Transformer
function Transformer:new(ast)
  local TransformerInstance = {}
  TransformerInstance.ast = ast
  TransformerInstance.nodeStack = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if TransformerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and TransformerInstance: " .. index)
      end
      TransformerInstance[index] = value
    end
  end

  -- Main
  inheritModule("TransformerMethods", TransformerMethods)

  -- Scope manager
  inheritModule("ScopeManager", ScopeManager:new())

  return TransformerInstance
end

return Transformer