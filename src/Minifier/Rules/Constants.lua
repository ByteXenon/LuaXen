--[[
  Name: Constants.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-09
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Constants *--
local MAX_VARIABLES_PER_NODE = 198

--* Imports *--
local insert = table.insert

--* Local functions *--
local function shallowCopyTable(table)
  local copy = {}
  for index, value in pairs(table) do
    copy[index] = value
  end
  return copy
end
local function splitVariables(variables, startIndex)
  local splitVariables = {}
  for i = startIndex, startIndex + MAX_VARIABLES_PER_NODE - 1 do
    insert(splitVariables, variables[i])
  end
  return splitVariables
end

--* ConstantsMethods *--
local ConstantsMethods = {}

function ConstantsMethods:localizeConstants()
  local ast = self.ast
  local metadata = ast._metadata
  local constants = metadata.constants
  local globalScope = metadata.globalScope
  local constantReuseThreshold = self.constantReuseThreshold
  local useGlobalsForConstants = self.useGlobalsForConstants

  local constantsMap = {
    Number = {},
    String = {}
  }

  for index, constantNode in ipairs(constants) do
    local constantType = constantNode.TYPE
    local constantValue = constantNode.Value

    constantsMap[constantType] = constantsMap[constantType] or {}
    constantsMap[constantType][constantValue] = constantsMap[constantType][constantValue] or {}
    insert(constantsMap[constantType][constantValue], constantNode)
  end

  local toLocalize = {}
  for constantType, constants in pairs(constantsMap) do
    for constantValue, constantNodes in pairs(constants) do
      if #constantNodes >= constantReuseThreshold then
        insert(toLocalize, { constantType, constantValue, constantNodes })
      end
    end
  end

  local usedVariables = self:getUsedVariablesInScope(globalScope)

  local namesForConstants = {}
  local constantsVariables = {}
  for index, constantData in ipairs(toLocalize) do
    local constantType, constantValue, constantNodes = constantData[1], constantData[2], constantData[3]
    local newName = self:generateName(usedVariables, "C")
    self.globalNames[newName] = true
    local oneNode = shallowCopyTable(constantNodes[1])
    for index, constantNode in ipairs(constantNodes) do
      constantNode.Value = newName
      constantNode.TYPE = "Variable"
    end

    if useGlobalsForConstants then
      insert(namesForConstants, NodeFactory.createGlobalVariableNode(newName))
    else
      insert(namesForConstants, newName)
    end
    insert(constantsVariables, NodeFactory.createExpressionNode(oneNode))
  end
  if #namesForConstants == 0 then return end

  -- Split assignments into MAX_VARIABLES_PER_NODE variables per node
  for index = 1, #constantsVariables, MAX_VARIABLES_PER_NODE do
    local splitConstantsVariables = splitVariables(constantsVariables, index)
    local splitNamesForConstants = splitVariables(namesForConstants, index)

    local node
    if useGlobalsForConstants then
      node = NodeFactory.createVariableAssignmentNode(splitNamesForConstants, splitConstantsVariables)
    else
      node = NodeFactory.createLocalVariableAssignmentNode(splitNamesForConstants, splitConstantsVariables)
    end
    insert(ast, 1, node)
  end
end

return ConstantsMethods