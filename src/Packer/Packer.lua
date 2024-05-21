--[[
  Name: Packer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaInterpreter = require("Interpreter/LuaInterpreter/LuaInterpreter")

local NodeFactory = LuaInterpreter.modules.NodeFactory
local NodeSpecs = LuaInterpreter.modules.NodeSpecs

--* Constants *--
local function REQUIRE_FUNCTIONCALL_CONDITION(node)
  return (node.TYPE == "LocalVariableAssignment"
          and node.Expressions[1]
          and node.Expressions[1].Value
          and node.Expressions[1].Value.Expression
          and node.Expressions[1].Value.Expression.Value == "require")
end


--* Imports *--
local insert = table.insert
local readFile = Helpers.readFile

local convertScriptToAST = LuaInterpreter.ConvertScriptToAST

local createStringNode                  = NodeFactory.createStringNode
local createFunctionNode                = NodeFactory.createFunctionNode
local createFunctionCallNode            = NodeFactory.createFunctionCallNode
local createLocalVariableNode           = NodeFactory.createLocalVariableNode
local createLocalVariableAssignmentNode = NodeFactory.createLocalVariableAssignmentNode

--* Local functions *--
local function topologicalSort(graph)
  local result, visited, temp = {}, {}, {}

  local function visit(node, graph)
    if temp[node] then
      error("The graph contains a cycle.")
    end

    if not visited[node] then
      temp[node] = true
      for neighbor, _ in pairs(graph[node]) do
        visit(neighbor, graph[node])
      end
      visited[node] = true
      temp[node] = nil
      insert(result, node)
    end
  end

  for node, _ in pairs(graph) do
    if not visited[node] then
      visit(node, graph)
    end
  end
  return result
end

--* PackerMethods *--
local PackerMethods = {}

function PackerMethods:sortDependencies(allDependencies)
  return topologicalSort(allDependencies)
end

function PackerMethods:traverseAST(ast, condition, callback)
  for index, node in ipairs(ast) do
    if condition(node) then
      callback(node, index)
    end
  end
end

function PackerMethods:getRequireFunctionCalls(ast)
  local requireFunctionCalls = {}
  local luaxenRequireFunctionCalls = {}
  self:traverseAST(ast, REQUIRE_FUNCTIONCALL_CONDITION, function(node)
    insert(requireFunctionCalls, node)
  end)

  return requireFunctionCalls, luaxenRequireFunctionCalls
end

function PackerMethods:getAllDependencies(ast, dependencies, moduleName, interpretedModules, nodeReferences)
  local dependencies = dependencies or {}
  local interpretedModules = interpretedModules or {}
  local moduleName = moduleName or "main"
  local nodeReferences = nodeReferences or {}

  local requireFunctionCalls, luaxenRequireFunctionCalls = self:getRequireFunctionCalls(ast)
  for _, requireFunctionCall in ipairs(requireFunctionCalls) do
    self:processRequireFunctionCall(requireFunctionCall, dependencies, interpretedModules, nodeReferences)
  end

  return dependencies, nodeReferences, interpretedModules
end

function PackerMethods:processRequireFunctionCall(requireFunctionCall, dependencies, interpretedModules, nodeReferences)
  local requirePath = requireFunctionCall.Expressions[1].Value.Arguments[1].Value.Value

  if not nodeReferences[requirePath] then
    nodeReferences[requirePath] = {}
  end
  insert(nodeReferences[requirePath], requireFunctionCall)
  if not dependencies[requirePath] then
    self:processRequiredModule(requirePath, dependencies, interpretedModules, nodeReferences)
  end
end

function PackerMethods:processRequiredModule(requirePath, dependencies, interpretedModules, nodeReferences)
  local moduleAst
  if not interpretedModules[requirePath] then
    local moduleContents = readFile(self.localizedPath .. requirePath .. ".lua")
    moduleAst = convertScriptToAST(moduleContents)
    interpretedModules[requirePath] = moduleAst
  else
    moduleAst = interpretedModules[requirePath]
  end

  local moduleDependencies = self:getAllDependencies(moduleAst, {}, requirePath, interpretedModules, nodeReferences)
  dependencies[requirePath] = moduleDependencies
end

function PackerMethods:createNewNodes(sortedOrder, nodeRefs, interpretedMod)
  local newNodes = {}

  for index, modPath in ipairs(sortedOrder) do
    local modAST = interpretedMod[modPath]
    local sanitizedModPath = modPath:gsub("/", "_"):gsub(" ", "_") .. "_module"
    local assignNode = self:createAssignNode(sanitizedModPath, modAST, modPath)

    newNodes[index] = assignNode
    self:updateReferences(nodeRefs, modPath, sanitizedModPath)
  end

  return newNodes
end

function PackerMethods:createAssignNode(sanitizedModPath, modAST, modPath)
  local funcNode = createFunctionNode({}, true, modAST)
  local funcCallNode = createFunctionCallNode(funcNode, {
    createStringNode(modPath)
  })
  return createLocalVariableAssignmentNode({sanitizedModPath}, {funcCallNode})
end

function PackerMethods:updateReferences(nodeRefs, modPath, sanitizedModPath)
  for _, ref in ipairs(nodeRefs[modPath]) do
    local varName = ref.Variables[1]
    for index, value in pairs(ref) do
      ref[index] = nil
    end
    local localVariable = createLocalVariableNode(sanitizedModPath)
    local newRef = createLocalVariableAssignmentNode({varName}, {localVariable})
    for index, value in pairs(newRef) do
      ref[index] = value
    end
  end
end

function PackerMethods:replaceAST(oldAST, newAST)
  for index, value in ipairs(oldAST) do
    insert(newAST, value)
  end
  newAST.TYPE = "AST"
  newAST._metadata = oldAST._metadata
  return newAST
end

-- Main (Public) --
function PackerMethods:pack()
  local oldAST = self.ast
  local allDependencies, nodeRefs, interpretedMod = self:getAllDependencies(self.ast)
  local sortedOrder = self:sortDependencies(allDependencies)
  local newAST = self:createNewNodes(sortedOrder, nodeRefs, interpretedMod)

  return self:replaceAST(oldAST, newAST)
end

--* Packer *--
local Packer = {}
function Packer:new(ast, localizedPath)
  local PackerInstance = {}
  PackerInstance.ast = ast
  PackerInstance.localizedPath = (localizedPath or "./")

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if PackerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and PackerInstance: " .. index)
      end
      PackerInstance[index] = value
    end
  end

  -- Main
  inheritModule("PackerMethods", PackerMethods)

  return PackerInstance
end

return Packer