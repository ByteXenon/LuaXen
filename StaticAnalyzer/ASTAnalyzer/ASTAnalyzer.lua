--[[
  Name: ASTAnalyzer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("StaticAnalyzer/ASTAnalyzer/ASTAnalyzer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local find = table.find or Helpers.TableFind
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