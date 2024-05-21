--[[
  Name: ModuleLoader.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local unpack = (unpack or table.unpack)
local readFile = Helpers.readFile

--* ModuleLoader *--
local ModuleLoader = {}

function ModuleLoader:loadFile(scriptPath)
  local environmentPath = self.state.globalEnvironment.package.path
  for path in environmentPath:gmatch("[^;]+") do
    local fullPath = path:gsub("?", scriptPath)
    local contents = readFile(fullPath)
    if contents then return contents end
  end
  return nil
end

function ModuleLoader:compileFile(contents)
  local Lexer = self.Lexer
  local Parser = self.Parser
  Lexer:resetToInitialState(contents)
  Parser:resetToInitialState(Lexer:tokenize(), false)
  return Parser:parse()
end

function ModuleLoader:executeFile(scriptPath)
  if self.loadedScripts[scriptPath] then
    -- Pull the return values from cache
    return unpack(self.loadedScripts[scriptPath])
  end

  local contents = self:loadFile(scriptPath)
  if not contents then return error("Could not find file: " .. scriptPath) end
  print("Loading file: " .. scriptPath)

  local ast = self:compileFile(contents)
  local returnValues = { self:executeIsolatedAST(ast) }
  self.loadedScripts[scriptPath] = returnValues
  return unpack(returnValues)
end

return ModuleLoader