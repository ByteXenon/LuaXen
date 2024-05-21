--[[
  Name: Minifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-09
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Constants = require("Minifier/Rules/Constants")
local Globals = require("Minifier/Rules/Globals")
local Locals = require("Minifier/Rules/Locals")

--* Constants *--
local DICT1 = "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local DICT2 = DICT1 .. "0123456789"

local DEFAULT_FORBIDDEN_NAMES = {
  -- Include only two-letter keywords/globals
  -- because for it to hit a three-letter keyword/global
  -- would require ~3276 combinations, which is improbable
  ["_G"] = true,
  ["if"] = true,
  ["do"] = true,
  ["io"] = true,
  ["in"] = true,
  ["or"] = true
}

--* Imports *--
local insert = table.insert
local floor = math.floor

--* Lookup Tables *--
local dict1Lookup = {}
local dict2Lookup = {}

for i = 1, (#DICT1) do dict1Lookup[i] = DICT1:sub(i, i) end
for i = 1, (#DICT2) do dict2Lookup[i] = DICT2:sub(i, i) end

--* Local functions *--
local function shallowCopyTable(table)
  local copy = {}
  for index, value in pairs(table) do
    copy[index] = value
  end
  return copy
end

--* MinifierMethods *--
local MinifierMethods = {}

-- Returns all variables used in a given scope, excluding a specific variable
function MinifierMethods:getUsedVariablesInScope(scope, exclude)
  if self.cache[scope] then return self.cache[scope] end
  if not scope then return {} end

  local usedVariables = {}
  local currentScope = scope
  while currentScope do
    for variableName, variable in pairs(currentScope.locals) do
      if variable ~= exclude then
        usedVariables[variableName] = variable
      end
    end
    currentScope = currentScope.parent
  end

  return usedVariables
end

-- Generates a unique name not present in existingNames or globalNames
function MinifierMethods:generateName(existingNames, prefix)
  local globalNames = self.globalNames
  local replacableNames = self.replacableNames

  if replacableNames then
    local prefix = (prefix or "L") .. "_"
    local counter = 0

    while true do
      local tempName = prefix .. counter .. "_"
      if not (existingNames[tempName] or globalNames[tempName]) then
        return tempName
      end
      counter = counter + 1
    end
    return
  end

  local counter, nameLength = 1, 1
  while true do
    local tempName = ""
    for i = 1, nameLength do
      local dict = (i == 1 and dict1Lookup) or dict2Lookup
      local dictLength = #dict
      local charIndex = floor(counter / (dictLength ^ (i - 1))) % dictLength + 1

      tempName = tempName .. dict[charIndex]
    end

    if not (existingNames[tempName] or globalNames[tempName]) then
      return tempName
    end

    counter = counter + 1
    if counter > (#dict2Lookup) ^ nameLength then
      counter, nameLength = 1, nameLength + 1
    end
  end
end

--- Generates names like L_1_
function MinifierMethods:generateReplacableName(existingNames)
  local counter = 0

  while true do
    local tempName = "L_" .. counter .. "_"
    if not (existingNames[tempName] or self.globalNames[tempName]) then
      return tempName
    end
    counter = counter + 1
  end
end

function MinifierMethods:minify()
  self:renameGlobals()

  if self.shouldLocalizeConstants then
    self:localizeConstants()
  end

  self:renameLocals()
end

--* Minifier *--
local Minifier = {}
function Minifier:new(ast, config)
  local MinifierInstance = {}
  MinifierInstance.ast = ast
  MinifierInstance.globalNames = shallowCopyTable(DEFAULT_FORBIDDEN_NAMES)
  MinifierInstance.cache = {}

  -- Config values
  local config = config or {}
  MinifierInstance.uniqueNames = (config.uniqueNames == nil and true) or config.uniqueNames -- Don't reuse names, even if they're out of scope
  MinifierInstance.replacableNames = (config.replacableNames == nil and false) or config.replacableNames -- Generate names like L_1_ or A_1_
  MinifierInstance.shouldLocalizeConstants = (config.shouldLocalizeConstants == nil and false) or config.shouldLocalizeConstants -- Localize constants if they're used more than constantReuseThreshold times
  MinifierInstance.constantReuseThreshold = (config.constantReuseThreshold or 5)
  MinifierInstance.useGlobalsForConstants = (config.useGlobalsForConstants == nil and false) or config.useGlobalsForConstants -- Use globals for defining constants

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if MinifierInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and MinifierInstance: " .. index)
      end
      MinifierInstance[index] = value
    end
  end

  -- Main
  inheritModule("MinifierMethods", MinifierMethods)

  -- Rules
  inheritModule("Constants", Constants)
  inheritModule("Globals", Globals)
  inheritModule("Locals", Locals)

  return MinifierInstance
end


return Minifier