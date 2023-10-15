--[[
  Name: NodeMethods.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTHierarchy/NodeMethods/NodeMethods")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeMethodsFunctions = ModuleManager:loadModule("ASTHierarchy/NodeMethods/NodeMethodsFunctions")
local NodeSpecs = ModuleManager:loadModule("ASTHierarchy/NodeSpecs")

--* NodeMethods *--
local NodeMethods = { AST = {}, Group = {} }
for index in pairs(NodeSpecs) do
  NodeMethods[index] = {}
end

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