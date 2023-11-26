--[[
  Name: ASTExecutor.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module executes an Abstract Syntax Tree (AST) of a Lua script. It handles 
    the execution of individual AST nodes and isolated code blocks, and manages 
    scopes for variable storage and control flow. It leverages functionality from 
    the ASTNodesFunctionality and ScopeManager modules. It is used by creating an 
    instance of the ASTExecutor class and calling its execute method with the AST.
--]]--[[
  TODO: ASTExecutor doesn't work as good with required scripts. It should be fixed
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("ASTExecutor/ASTExecutor")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local LuaState = ModuleManager:loadModule("LuaState/LuaState")
local ASTNodesFunctionality = ModuleManager:loadModule("ASTExecutor/ASTNodesFunctionality")
local ScopeManager = ModuleManager:loadModule("ASTExecutor/ScopeManager")
local DebugLibrary = ModuleManager:loadModule("ASTExecutor/DebugLibrary")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
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

--* Class methods *--
local ASTExecutorMethods = {}

-- This function is used to reset the variables that are used to store
-- values between function calls. It's necessary to avoid leaks.
function ASTExecutorMethods:resetExecutionState()
  self.returnValues = nil
  self.lastExecutedNode = nil
  self.globalFlags.returnFlag = false
  self.globalFlags.continueFlag = false
  self.globalFlags.breakFlag = false
end

function ASTExecutorMethods:executeNode(node, state)
  local nodeType = node.TYPE
  local globalFlags = self.globalFlags

  -- We under ANY circumstances DO NOT execute nodes that are not expected to be executed.
  -- Generally, it's a sign of a bug in the ASTExecutor, so we throw an error, instead of ignoring it.
  if     globalFlags.returnFlag   then return error("Return flag is set, but it wasn't handled")
  elseif globalFlags.continueFlag then return error("Continue flag is set, but it wasn't handled")
  elseif globalFlags.breakFlag    then return error("Break flag is set, but it wasn't handled")
  end

  -- Skip expressions, they're just wrappers for other nodes
  if nodeType == "Expression" then
    node = node.Value
    nodeType = node.TYPE
  end
  
  local astNodeFunction = self[nodeType]
  if astNodeFunction then
    return astNodeFunction(self, node, state)
  end

  -- If the node is not a valid/supported AST node, throw an error
  return error("Invalid or unsupported node: " .. stringifyTable(node or {}))
end

--- Executes a list of AST nodes.
--- This function shouldn't generally be called directly, as it doesn't handle
--- scopes and control flow. Use executeCodeBlock instead.
function ASTExecutorMethods:executeNodes(nodes, state, checkFlags)
  -- Optimization: If there's only one node, don't create a loop
  if not nodes[1] then return {} end
  local globalFlags = self.globalFlags

  local results = {}
  for index, node in ipairs(nodes) do
    -- Execute the node and store the return values
    local nodeReturnValues = { self:executeNode(node, state) }
    for _, returnValue in ipairs(nodeReturnValues) do
      insert(results, returnValue)
    end

    -- Check for control flow flags and break if necessary
    if checkFlags then
      if globalFlags.returnFlag then
        return
      elseif globalFlags.continueFlag then
        -- Just break the loop, let the loop handlers handle it.
        break
      elseif globalFlags.breakFlag then
        -- Just break the loop, let the loop handlers handle it.
        break
      end
    end
  end

  return results
end

--- Creates a Lua function that executes the given code block with the specified parameters.
-- The created function takes any number of arguments, passes them to the code block,
-- and returns the return values of the code block.
function ASTExecutorMethods:makeLuaFunction(parameters, codeBlock, state)
  -- Basically, it's a mechanism for perserving upvalues for shared functions
  -- (functions that are used in multiple places, for example, in a module).
  -- so we store local scope stack in a variable, so the function can use it
  -- to access upvalues.
  local oldScopes = shallowCopyTable(self.scopes)

  local functionScriptName = self.scriptName

  -- This is a function that will be called during function calls.
  return (function(...)
    -- [Prologue] {
    local newScopes = self.scopes
    self.scopes = oldScopes
    self.currentScope = oldScopes[#oldScopes]
    self:pushScope()

    local args = {...}
    local newScope = self.currentScope
    -- TODO: Check whether or not we should store the environment
    -- table at the beginning too
    local functionState = LuaState:new()
    functionState.env = state.env
    -- }

    -- [Body] {
    -- Register the parameters in the current scope
    for index, parameterName in ipairs(parameters) do
      if parameterName == "..." then
        -- Make a table of values after "index" and pass it as a vararg
        local varArg = { select(index, unpack(args)) }
        self:registerVariable("...", varArg)
        break
      end

      local paramValue = args[index]
      self:registerVariable(parameterName, paramValue)
    end
    -- Execute the code block
    self:executeNodes(codeBlock, functionState, true)
    -- }

    -- [Epilogue] {
    -- Pop the scope of the function scope stack, not the current one
    -- this is because we make a shallow copy of the scope stack at the beginning
    -- for the function to use upvalues (even if they're not present right now,
    -- for example, when we require a module).
    self:popScope() -- Remove it for further uses

    -- Return to the old, pre-functioncall scope stack
    self.currentScope = newScopes[#newScopes]
    -- self:popScope() : We don't need it, because we switched scope stacks
    self.scopes = newScopes -- Restore the old scope stack

    local returnValues = self.returnValues
    -- Clear returnValues and flow flags to avoid leaks. This is necessary because
    -- they're stored globally and could be overwritten by subsequent function calls.
    self:resetExecutionState()
    
    return unpack(returnValues or {})
    -- }
  end)
end

-- A function to execute a node list in an isolated environment
function ASTExecutorMethods:executeCodeBlock(nodeList, state)
  -- [Prologue] {
  self:pushScope()
  local newScope = self.currentScope
  -- }

  -- [Body] {
  self:executeNodes(nodeList, state, true)
  -- }

  -- [Epilogue] {
  -- If there's a logical error in some code underneath
  -- ... revert it back despite not having proper scope
  -- pushing/poping logic. It will silently solve some problems.
  self.currentScoe = newScope
  self:popScope()
  -- }
end

--- The main function of the module. Executes the AST.
function ASTExecutorMethods:execute(...)
  -- [Prologue] {
  if self.debug then
    -- If debugging is enabled, set the debugging globals
    self:setDebuggingGlobals(self.state)
  end

  self:pushScope()
  -- Register the vararg variable in the current scope,
  -- so it can be accessed by all the functions in the script
  self:registerVariable("...", {...})
  -- }

  -- [Body] {
  self:executeCodeBlock(self.ast, self.state)
  --local success, errorMsg = pcall(self.executeCodeBlock, self, self.ast, self.state)
  -- }

  -- [Epilogue] {
  local returnValues = self.returnValues
  local lastExecutedNode = self.lastExecutedNode

  self:popScope()
  -- Clear "self" variables to avoid leaks in case it gets reused again.
  self:resetExecutionState()

  --[[
  -- Check if the script errored
  if not success then
    -- If the script errored, print the error and return
    print("[ASTExecutor] Error executing script: " .. tostring(errorMsg) .. " [in " .. tostring(self.scriptName) .. "]")
    print("Last executed node: " .. stringifyTable(lastExecutedNode or {}))
    return error("Internal ASTExecutor error")
  end
  --]]

  return returnValues and unpack(returnValues)
  -- }
end

--* ASTExecutor *--
local ASTExecutor = {}
function ASTExecutor:new(AST, state, debug, scriptName)
  local ASTExecutorInstance = {}

  ASTExecutorInstance.ast = AST
  ASTExecutorInstance.debug = debug
  ASTExecutorInstance.scriptName = scriptName or "unknown"
  ASTExecutorInstance.state = (state or LuaState:new())
  -- Return values are stored globally, because it would
  -- be pain to store them in individual scopes, because
  -- scopes are being created not only for functions, but
  -- for code blocks too (do <codeblock> end)
  ASTExecutorInstance.returnValues = nil
  -- Store last executed node for debugging purposes
  ASTExecutorInstance.lastExecutedNode = nil

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
  inheritModule("ScopeManager", ScopeManager:new())

  if debug then
    inheritModule("DebugLibrary", DebugLibrary)
  end

  return ASTExecutorInstance
end

return ASTExecutor