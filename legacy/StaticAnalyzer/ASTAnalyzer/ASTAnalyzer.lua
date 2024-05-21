--[[
  Name: ASTAnalyzer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local find = table.find or Helpers.tableFind
local insert = table.insert

--* ASTAnalyzer *--
local ASTAnalyzer = {}
function ASTAnalyzer:new(astHierarchy)
  local ASTAnalyzerInstance = {}

  function ASTAnalyzerInstance:getLocalNames(scope)
    local currentScope = (scope or astHierarchy)
    local localNames = {}

    local localVariables = currentScope:getDescendantsWithType("LocalVariable")
    for _, localVariable in ipairs(localVariables) do
      for __, localIdentifier in pairs(localVariable.Variables) do
        local IdentifierValue = localIdentifier.Value
        if not find(localNames, IdentifierValue) then
          insert(localNames, IdentifierValue)
        end
      end
    end

    return localNames
  end
  function ASTAnalyzerInstance:isALocal(localName, scope)
    local currentScope = (scope or astHierarchy)
    local scopeLocals = self:getLocalNames(scope)
    local foundLocal = find(scopeLocals, localName)

    return foundLocal ~= nil
  end

  return ASTAnalyzerInstance
end

return ASTAnalyzer