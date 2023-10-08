--[[
  Name: NodeMethodsFunctions.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/NodeMethods/NodeMethodsFunctions")
local NodeSpecs = ModuleManager:loadModule("ASTHierarchy/NodeSpecs")

--* Export library functions *--
local insert = table.insert

--* _Default *--
local _Default = {}

-- Get node's type
function _Default:getType(node)   return node.TYPE    end
-- Get the parent of the node
function _Default:getParent(node) return node.Parents end

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

-- Get children of the node that have the type of "type"
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

-- Get descendants of the node that have the type of "type"
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

--* NodeMethodsInfo *--
local NodeMethodsInfo = {
  _Default = _Default
}

return NodeMethodsInfo