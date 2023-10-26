--[[
  Name: ASTHierarchy.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/ASTHierarchy")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeMethods = ModuleManager:loadModule("ASTHierarchy/NodeMethods/NodeMethods")
local NodeSpecs = ModuleManager:loadModule("ASTHierarchy/NodeSpecs")

--* ASTHierarchy *--
local ASTHierarchy = {}
function ASTHierarchy:new(AST)
  local ASTHierarchyInstance = {}
  ASTHierarchyInstance.ast = AST

  function ASTHierarchyInstance:applyMethods(node)
    local nodeType = node.TYPE
    for index, method in pairs(NodeMethods[nodeType]) do
      node[index] = function(self, ...) return method(self, node, ...) end
    end
  end
  function ASTHierarchyInstance:traverseNodeChildren(node)
    local nodeType = node.TYPE
    local nodeSpec = NodeSpecs[nodeType]

    if nodeType == "AST" or nodeType == "Group" then
      for index, childNode in ipairs(node) do
        self:transformNode(childNode, node, index)
      end
    else
      self:processNodeSpec(node, nodeSpec)
    end
  end

  function ASTHierarchyInstance:processNodeSpec(node, nodeSpec)
    for index, indexType in pairs(nodeSpec) do
      if indexType == "Node" or indexType == "OptionalNode" then
        self:transformNode(node[index], node, index)
      elseif indexType == "NodeList" then
        self:processNodeList(node, index)
      end
    end
  end

  function ASTHierarchyInstance:processNodeList(node, index)
    for index2, childNode in ipairs(node[index]) do
      self:transformNode(childNode, node[index], (index .. ">" .. index2))
    end
  end

  function ASTHierarchyInstance:transformNode(node, parent, parentIndex)
    if not node then return end
    node.TYPE = node.TYPE or "AST"
    node.Parent = parent
    node.ChildIndex = parentIndex
    node.Root = self.ast

    self:applyMethods(node)
    self:traverseNodeChildren(node)

    if not parent then return node end
  end

  function ASTHierarchyInstance:convert()
    return self:transformNode(self.ast)
  end

  return ASTHierarchyInstance
end

return ASTHierarchy