--[[
  Assembler Example
  ==============================
  This script demonstrates how to use the Lua API to execute assembly code.
  It first sets up the required paths and modules, then defines and executes the assembly code.
--]]

-- Localize the path, so this file can be ran from anywhere
local scriptPath = (debug.getinfo(1).source:match("@?(.*/)") or "")
local requirePath = scriptPath .. "../src/?.lua"
local localPath = scriptPath .. "../src/"
package.path = requirePath

-- Import required modules
local luaAPI = require("api")
local Helpers = luaAPI.Modules.Helpers

local testScript = "print('Hello, world!')"
local obfuscatedScript = luaAPI.Obfuscator.IronBrikked.ObfuscateScript(testScript)

-- Stage 2 (optional)
-- local obfuscatedScript2 = luaAPI.Obfuscator.ASTObfuscator.ObfuscateScript(obfuscatedScript)

local printedAST = luaAPI.Printer.ASTPrinter.PrintScriptAST(obfuscatedScript)
print(printedAST)