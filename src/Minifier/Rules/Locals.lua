--[[
  Name: Locals.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-09
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert

--* Constants *--
local RENAME_FIELDS_NODES = {
  ["FunctionDeclaration"] = "Parameters",
  ["Function"]            = "Parameters",
  ["MethodDeclaration"]   = "Parameters",
  ["LocalFunction"]       = "Parameters",

  ["GenericFor"] = "IteratorVariables",
  ["NumericFor"] = "IteratorVariables",

  ["LocalVariableAssignment"] = "Variables"
}


--* LocalsMethods *--
local LocalsMethods = {}

function LocalsMethods:renameLocals()
  local ast = self.ast
  local uniqueNames = self.uniqueNames
  local globalNames = self.globalNames
  local metadata = ast._metadata
  local locals = metadata.variables

  for variableIndex, variable in ipairs(locals) do
    local variableName = variable.Name
    local variableScope = variable.Scope
    local variableReferences = variable.References
    local variableAssignmentNodes = variable.AssignmentNodes
    local variableDeclarationNode = variable.DeclarationNode
    assert(variableDeclarationNode)

    local usedVariables = (self:getUsedVariablesInScope(variableScope, variable))
    local newName = self:generateName(usedVariables or globalNames)

    if uniqueNames then
      globalNames[newName] = true
    else
      variableScope.locals[variableName] = nil
      variableScope.locals[newName] = variable
    end

    variable.Name = newName
    -- variableScope.locals[newName] = variable
    -- variable.Name = newName
    if #variableAssignmentNodes == 0 then
      -- Constant
    end

    if not (variableName == "self" and variableDeclarationNode.TYPE == "MethodDeclaration") then
      for referenceIndex, reference in ipairs(variableReferences) do
        reference.Value = newName
      end
      local nodeType = variableDeclarationNode.TYPE
      local nodeListToRename = RENAME_FIELDS_NODES[nodeType]
      if not nodeListToRename then
        error("Failed to find node list to rename for node: " .. tostring(nodeType))
      end

      local nodeList = variableDeclarationNode[nodeListToRename]
      local renamed = false
      for index = #nodeList, 1, -1 do
        local name = nodeList[index]
        if name == variableName then
          nodeList[index] = newName
          renamed = true
          break
        end
      end

      if not renamed and nodeType == "LocalFunction" then
        if variableDeclarationNode.Name == variableName then
          variableDeclarationNode.Name = newName
          renamed = true
        end
      end

      assert(renamed, "Failed to rename variable: " .. variableName)
    end
  end
end

return LocalsMethods