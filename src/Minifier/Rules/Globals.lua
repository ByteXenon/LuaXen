--[[
  Name: Globals.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-08
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local insert = table.insert

--* GlobalsMethods *--
local GlobalsMethods = {}

function GlobalsMethods:renameGlobals()
  local ast = self.ast
  local metadata = ast._metadata
  local globals = self.ast._metadata.globals

  local newGlobalNames = {}
  local globalExpressions = {}
  for globalIndex, globalVariable in ipairs(globals) do
    local globalName = globalVariable.Name
    local globalReferences = globalVariable.References
    local globalDeclarationNodes = globalVariable.DeclarationNodes
    local globalScope = globalVariable.Scope
    local newName = self:generateName(self:getUsedVariablesInScope(globalScope), "G")
    if #globalDeclarationNodes == 0 then
      self.globalNames[newName] = true
      insert(newGlobalNames, newName)
      insert(globalExpressions, NodeFactory.createGlobalVariableNode(globalName))
      for referenceIndex, reference in ipairs(globalReferences) do
        reference.Value = newName
      end
    end
  end
  if #newGlobalNames == 0 then
    return
  end

  local node = NodeFactory.createLocalVariableAssignmentNode(newGlobalNames, globalExpressions)
  insert(self.ast, 1, node)
end

return GlobalsMethods