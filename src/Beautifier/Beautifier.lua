--[[
  Name: Beautifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-29
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")

--* Imports *--
local stringifyTable = Helpers.stringifyTable

--* BeautifierMethods *--
local BeautifierMethods = {}

function BeautifierMethods:processNode(node)
  local nodeType = node.TYPE
  local nodeSpec = NodeSpecs[nodeType]
  for nodeField, nodeType in pairs(nodeSpec) do
    if nodeType == "Node" then
      self:processNode(node[nodeField])
    elseif nodeType == "OptionalNode" then
      if node[nodeField] then
        self:processNode(node[nodeField])
      end
    elseif nodeType == "NodeList" then
      self:processNodeList(node[nodeField])
    end
  end

  node._metadata = node._metadata or {}
  node._metadata.indentation = self.indentation
end

function BeautifierMethods:processNodeList(nodeList)
  for index, node in ipairs(nodeList) do
    self:processNode(node)
  end
end

function BeautifierMethods:beautify()
  return self:processNodeList(self.ast)
end

--* Beautifier *--
local Beautifier = {}
function Beautifier:new(ast)
  local BeautifierInstance = {}
  BeautifierInstance.ast = ast
  BeautifierInstance.indentation = 5

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if BeautifierInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and BeautifierInstance: " .. index)
      end
      BeautifierInstance[index] = value
    end
  end

  -- Main
  inheritModule("BeautifierMethods", BeautifierMethods)

  return BeautifierInstance
end

return Beautifier