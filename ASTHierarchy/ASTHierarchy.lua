--[[
  Name: ASTHierarchy.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/ASTHierarchy")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeSpecs = ModuleManager:loadModule("ASTHierarchy/NodeSpecs")
local DefaultType = ModuleManager:loadModule("ASTHierarchy/Types/Default")

--* ASTHierarchy *--
local ASTHierarchy = {}
function ASTHierarchy:new(AST)
  local ASTHierarchyInstance = {}
  ASTHierarchyInstance.ast = AST
  function ASTHierarchyInstance:convertToOOPForm(node, parent, parentIndex)
    if not type(node) == "table" then return end
    local nodeType = node.TYPE or "ASTList"
    
    local nodeProxy = newproxy(true)
    getmetatable(nodeProxy).__index = node
    getmetatable(nodeProxy).__newindex = node

    convertToOOPFormIfExists({"Expression"})
    convertList(node.CodeBlock)
    convertList(node.Expressions)
    convertList(node.Variables)
    convertList(node.Parameters)

    for index, value in pairs(defaultType) do
      nodeProxy[index] = value
    end
    nodeProxy.Type = nodeType
    nodeProxy.Original = node 
    nodeProxy.Parent = parent
    nodeProxy.ChildIndex = parentIndex
    parent[parentIndex] = nodeProxy

  end
  function ASTHierarchyInstance:convert()
    local ast = self.ast
    for index, value in ipairs(ast) do
      self:convertToOOPForm(value, ast, index)
    end
    return ast
  end

  return ASTHierarchyInstance
end

return ASTHierarchy