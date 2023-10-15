--[[
  Name: NodeMethodsFunctions.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/NodeMethods/NodeMethodsFunctions")
local NodeSpecs = ModuleManager:loadModule("ASTHierarchy/NodeSpecs")

local ASTAnalyzer = ModuleManager:loadModule("StaticAnalyzer/ASTAnalyzer/ASTAnalyzer")
local ASTToTokensConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local Printer = ModuleManager:loadModule("Printer/Printer")

--* Export library functions *--
local insert = table.insert

--* _Default *--
local _Default = {}

--* Identifier *--
local Identifier = {}

-- Get the type of the node
function _Default:getType(node)   return node.TYPE    end
-- Get the parent of the node
function _Default:getParent(node) return node.Parent end
-- Remove node from its parent
function _Default:remove(node)
  local parent = node.Parent
  local index = node.ChildIndex
  if not parent or not index then return end
  local parentType = parent.TYPE
  if parentType == "AST" or parentType == "Group" then
    local indexCounter = 1
    local newTb = {}
    for childIndex, childNode in ipairs(node.Parent) do
      if childIndex ~= index then
        node.Parent[indexCounter] = childNode
        indexCounter = indexCounter + 1
      end
    end
    node.Parent[indexCounter] = nil
  else
    node.Parent[index] = nil
  end
end
-- Get children of the node
function _Default:getChildren(node)
  local nodeType = node.TYPE
  local nodeSpec = NodeSpecs[nodeType]

  if nodeType == "AST" then
    return {unpack(node)}
  end

  local children = {}
  for index, indexType in pairs(nodeSpec) do
    if indexType == "Node" or indexType == "OptionalNode" then
      insert(children, node[index])
    elseif indexType == "NodeList" then
      for index2, node in ipairs(node[index]) do
        insert(children, node)
      end
    elseif indexType == "Value" then
    end
  end

  return children
end
-- Get descendants of the node
function _Default:getDescendants(node)
  local descendants = {}

  local recursiveGet;
  local function recursiveGet(node)
    for index, childNode in pairs(node:getChildren()) do
      recursiveGet(childNode)
      insert(descendants, childNode)
    end
  end

  recursiveGet(node)
  return descendants
end
-- Get children with specific type
function _Default:getChildrenWithType(node, type)
  local children = node:getChildren()
  local childrenWithSpecificType = {}
  for index, node in ipairs(children) do
    if node.TYPE == type then
      insert(childrenWithSpecificType, node)
    end
  end
  return childrenWithSpecificType
end
-- Get descendants with specific type
function _Default:getDescendantsWithType(node, type)
  local descendants = node:getDescendants()
  local descendantsWithSpecificType = {}
  for index, node in ipairs(descendants) do
    if node.TYPE == type then
      insert(descendantsWithSpecificType, node)
    end
  end
  return descendantsWithSpecificType
end
-- Get values of the node without methods
function _Default:getOriginalIndices(node)
  local nodeType = node.TYPE
  if nodeType == "AST" then
    return unpack(node)
  end

  local tb = {}
  local nodeSpec = NodeSpecs[nodeType]
  for index, value in ipairs(nodeSpec) do
    tb[index] = node[index]
  end
  return tb
end
function _Default:getTokens(node)
  local nodeType = node.TYPE
  if nodeType == "AST" or nodeType == "Group" then
    return ASTToTokensConverter:new(node):run()
  end
  return ASTToTokensConverter:new(node):tokenizeNode(node)
end
function _Default:printTokens(node)
  local tokens = node:getTokens()
  return Printer:new(node):run()
end
-- Check if identifier is a local variable
function Identifier:isALocal(node, scope)
  local astAnalyzer = ASTAnalyzer:new(self.Root)
  return astAnalyzer:isALocal(node.Value, scope)
end

--* NodeMethodsInfo *--
local NodeMethodsInfo = {
  _Default = _Default,
  Identifier = Identifier
}

return NodeMethodsInfo