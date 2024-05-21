--[[
  Name: ASTWalker.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-06
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local insert = table.insert
local unpack = (unpack or table.unpack)

--* ASTWalkerMethods *--
local ASTWalkerMethods = {}

function ASTWalkerMethods.getNodeChildren(node)
  local nodeType = node.TYPE
  local nodeSpec = NodeSpecs[nodeType]
  if not nodeSpec then error("NodeSpec not found for node type: " .. nodeType) end

  local children = {}
  for fieldName, fieldType in pairs(nodeSpec) do
    if fieldType == "Node" then
      insert(children, node[fieldName])
    elseif fieldType == "OptionalNode" then
      if node[fieldName] then
        insert(children, node[fieldName])
      end
    elseif fieldType == "NodeList" then
      for _, child in ipairs(node[fieldName]) do
        insert(children, child)
      end
    end
  end

  return children
end

function ASTWalkerMethods.traverseNode(node, condition, callback)
  if condition(node) then
    callback(node)
  end

  local children = ASTWalkerMethods.getNodeChildren(node)
  for _, child in ipairs(children) do
    ASTWalkerMethods.traverseNode(child, condition, callback)
  end
end

function ASTWalkerMethods.traverseAST(ast, condition, callback)
  local function traverseNode(node)
    if condition(node) then
      callback(node)
    end

    local children = ASTWalkerMethods.getNodeChildren(node)
    for _, child in ipairs(children) do
      traverseNode(child)
    end
  end

  for index, node in ipairs(ast) do
    traverseNode(node)
  end
end

return ASTWalkerMethods