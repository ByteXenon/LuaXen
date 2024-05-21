--[[
  Name: ASTExecutor.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
  Description:
    This module executes an Abstract Syntax Tree (AST) of a Lua script. It handles
    the execution of individual AST nodes and isolated code blocks, and manages
    scopes for variable storage and control flow. It leverages functionality from
    the ASTNodesFunctionality and ScopeManager modules. It is used by creating an
    instance of the ASTExecutor class and calling its execute method with the AST.
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("Structures/LuaState")

local ASTNodesFunctionality = require("ASTExecutor/ASTNodesFunctionality")
local ScopeManager = require("ASTExecutor/ScopeManager")
local ModuleLoader = require("ASTExecutor/ModuleLoader")

local Lexer  = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local insert = table.insert
local unpack = (unpack or table.unpack)

--* Local functions *--
local function shallowCopyTable(table1)
  local table2 = {}
  for index, value in pairs(table1) do
    table2[index] = value
  end
  return table2
end
local function customUnpack(table, numberOfValues)
  if numberOfValues == 0 then return end
  local function unpackHelper(startIndex)
    if startIndex > numberOfValues then return end
    return table[startIndex], unpackHelper(startIndex + 1, numberOfValues)
  end
  return unpackHelper(1)
end

--* Class methods *--
local ASTExecutorMethods = {}

-- This function is used to clear global state values to avoid leaks.
function ASTExecutorMethods:resetExecutionState()
  self.returnValues = nil
  self.returnValuesAmount = nil
  -- Flags
  self.flags.returnFlag = false
  self.flags.continueFlag = false
  self.flags.breakFlag = false
end

function ASTExecutorMethods:executeNode(node)
  local nodeType = node.TYPE
  local astNodeFunction = self[nodeType]
  if astNodeFunction then
    return astNodeFunction(self, node)
  end

  error("Invalid or unsupported node: " .. stringifyTable(node or {}))
  return
end

function ASTExecutorMethods:executeExpressionNode(node)
  local nodeType = node.TYPE

  -- Skip expressions, they're just wrappers for other nodes
  while nodeType == "Expression" do
    node = node.Value
    nodeType = node.TYPE
  end

  local astNodeFunction = self[nodeType]
  if astNodeFunction then
    return astNodeFunction(self, node)
  end

  error("Invalid or unsupported node: " .. stringifyTable(node or {}))
  return
end

--- Executes a list of AST nodes.
--- This function shouldn't generally be called directly, as it doesn't handle
--- scopes and control flow. Use executeCodeBlock instead.
function ASTExecutorMethods:executeNodes(nodes)
  -- Optimization: If there's no nodes, return nil.
  if not nodes[1] then return end
  local flags = self.flags

  for index, node in ipairs(nodes) do
    self:executeNode(node)

    -- Check for control flow flags
    if flags.returnFlag then
      return
    elseif flags.continueFlag then
      -- Just break the loop, let the loop handlers handle it.
      break
    elseif flags.breakFlag then
      -- Just break the loop, let the loop handlers handle it.
      break
    end
  end
end

function ASTExecutorMethods:executeExpressionNodes(nodes)
  -- Optimization: If there's no nodes, return an empty table.
  if not nodes[1] then return {}, 0 end

  local results = {}
  local resultsIndex = 0
  for index, node in ipairs(nodes) do
    -- Execute the node and store the return values
    local nodeReturnValues = { self:executeExpressionNode(node) }
    if #nodeReturnValues == 0 then
      -- Each node should return at least one value, so we insert nil if it doesn't.
      resultsIndex = resultsIndex + 1
      results[resultsIndex] = nil
    else
      for _, returnValue in ipairs(nodeReturnValues) do
        resultsIndex = resultsIndex + 1
        results[resultsIndex] = returnValue
      end
    end
  end

  return results, resultsIndex
end

--- Creates a Lua function that executes the given code block with the specified parameters.
-- The created function takes any number of arguments, passes them to the code block,
-- and returns the return values of the code block.
function ASTExecutorMethods:makeLuaFunction(parameters, isVararg, codeBlock)
  -- Basically, it's a mechanism for perserving upvalues for shared functions
  -- (functions that are used in multiple places, for example, in a required module).
  -- so we store local scope stack in a variable, so the function can use it
  -- to access old upvalues that were removed in the current scope.
  local oldScopes = shallowCopyTable(self.scopes)
  local parameters = parameters
  local isVararg = isVararg
  local codeBlock = codeBlock

  return function(...)
    -- [Prologue] {
    local newScopes = self.scopes
    self.scopes = oldScopes
    self.currentScope = oldScopes[#oldScopes]

    self:pushScope(true)

    local args = {...}
    local argsLen = select("#", ...)
    local newScope = self.currentScope
    -- }

    -- [Body] {
    -- Register the parameters in the current scope
    for index, parameterName in ipairs(parameters) do
      local paramValue = args[index]
      self:registerVariable(parameterName, paramValue)
    end

    -- Register the vararg variable in the new scope,
    if isVararg then
      -- Put all the arguments that weren't assigned to parameters into the vararg
      local varArg = {}
      for index = #parameters + 1, argsLen do
        varArg[index - #parameters] = args[index]
      end
      self:registerVariable("...", varArg)
    elseif argsLen > #parameters then
      -- Soft error potential.
      -- Too many arguments were passed to the function,
      -- let's not make the user's life harder and just ignore them.
    end

    -- Execute the code block
    self:executeNodes(codeBlock)
    -- }

    -- [Epilogue] {
    self.currentScope = newScope
    self:popScope()
    self.scopes = newScopes -- Restore the old scope stack
    self.currentScope = newScopes[#newScopes]

    local returnValues = self.returnValues or {}
    local returnValuesAmount = self.returnValuesAmount or 0
    -- Clear returnValues and flow flags to avoid leaks. This is necessary because
    -- they're stored globally and could be overwritten by subsequent function calls.
    self:resetExecutionState()

    return customUnpack(returnValues, returnValuesAmount)
    -- }
  end
end

-- A function to execute a node list in an isolated environment
function ASTExecutorMethods:executeCodeBlock(nodeList, isFunctionScope)
  -- [Prologue] {
  local oldScope = self.currentScope
  local oldScopes = self.scopes

  self:pushScope(isFunctionScope)
  -- }

  -- [Body] {
  self:executeNodes(nodeList)
  -- }

  -- [Epilogue] {
  -- If there's a logical error in some code underneath
  -- - revert it back despite not having proper scope
  -- pushing/poping logic. It will silently solve some problems.
  self.scopes = oldScopes
  self:popScope()
  self.currentScope = oldScope
  -- }
end

--- The function to execute the entire AST.
function ASTExecutorMethods:executeAST(ast, ...)
  -- [Prologue] {
  -- Push the global scope, this one
  -- is special, because we don't pop it
  self:pushScope()
  -- }

  -- [Body] {
  -- Register the vararg variable in the new scope,
  -- so it can be accessed by all the functions in the script
  self:registerVariable("...", {...})
  self:executeCodeBlock(ast, false)
  -- }

  -- [Epilogue] {
  local returnValues = self.returnValues or {}
  local returnValuesAmount = self.returnValuesAmount or 0
  self:resetExecutionState()

  return customUnpack(returnValues, returnValuesAmount)
  -- }
end

--- Executes an AST in an isolated environment, like it's a new ASTExecutor instance.
function ASTExecutorMethods:executeIsolatedAST(ast, ...)
  -- Save the current state
  local savedAst = self.ast
  local savedDebug = self.debug
  local savedScriptName = self.scriptName
  local savedState = self.state
  local savedFlags = self.flags
  local savedReturnValues = self.returnValues
  local savedReturnValuesAmount = self.returnValuesAmount
  local savedScopes = self.scopes
  local savedCurrentScope = self.currentScope

  -- Reset the state and execute the new AST
  self:resetToInitialState(ast)
  local returnValues = { self:executeAST(ast, ...) }

  -- Restore the saved state
  self.ast = savedAst
  self.debug = savedDebug
  self.scriptName = savedScriptName
  self.state = savedState
  self.flags = savedFlags
  self.returnValues = savedReturnValues
  self.returnValuesAmount = savedReturnValuesAmount
  self.scopes = savedScopes
  self.currentScope = savedCurrentScope

  return unpack(returnValues or {})
end

--- The main function of the module. Executes the AST.
function ASTExecutorMethods:execute(...)
  -- Modify the 'require' function in the global environment
  self.state.globalEnvironment.require = function(scriptPath)
    return self:executeFile(scriptPath)
  end

  -- Execute the AST
  return self:executeAST(self.ast)
end

--- Resets the ASTExecutor to its initial state.
-- @param AST The new AST to execute.
-- @param state The new LuaState to use.
-- @param debug Whether to print debug information.
-- @param scriptName The name of the script being executed.
function ASTExecutorMethods:resetToInitialState(AST, state, debug, scriptName)
  self.ast = AST
  self.debug = debug
  self.scriptName = scriptName or "unknown"
  self.state = state or LuaState:new()
  self.flags = {
    returnFlag = false,
    breakFlag = false,
    continueFlag = false
  }
  self.returnValues = nil
  self.returnValuesAmount = nil
  self.scopes = {}
  self.currentScope = { locals = {} }
end

--* ASTExecutor *--
local ASTExecutor = {}
function ASTExecutor:new(AST, state, debug, scriptName)
  local ASTExecutorInstance = {}

  ASTExecutorInstance.ast = AST
  ASTExecutorInstance.debug = debug
  ASTExecutorInstance.scriptName = scriptName or "unknown"
  ASTExecutorInstance.state = (state or LuaState:new())
  ASTExecutorInstance.flags = {
    returnFlag = false,
    breakFlag = false,
    continueFlag = false
  }
  -- Return values are stored globally, because it would
  -- be a pain to store them in individual scopes, because
  -- scopes are being created not only for functions, but
  -- for code blocks too (do <codeblock> end)
  ASTExecutorInstance.returnValues = nil
  ASTExecutorInstance.returnValuesAmount = nil
  -- Scope manager stuff
  ASTExecutorInstance.scopes = {}
  ASTExecutorInstance.currentScope = { locals = {} }
  -- ModuleLoader stuff
  ASTExecutorInstance.loadedScripts = {}
  ASTExecutorInstance.Lexer = Lexer:new()
  ASTExecutorInstance.Parser = Parser:new()

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ASTExecutorInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ASTExecutorInstance: " .. index)
      end
      ASTExecutorInstance[index] = value
    end
  end

  -- Main
  inheritModule("ASTExecutorMethods", ASTExecutorMethods)

  -- Other modules
  inheritModule("ASTNodesFunctionality", ASTNodesFunctionality)
  inheritModule("ModuleLoader", ModuleLoader)
  inheritModule("ScopeManager", ScopeManager)

  return ASTExecutorInstance
end

return ASTExecutor