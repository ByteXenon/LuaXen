-- Localize the path, so this file can be ran from anywhere
local scriptPath = (debug.getinfo(1).source:match("@?(.*/)") or "")
local requirePath = scriptPath .. "../src/?.lua"
local localPath = scriptPath .. "../src/"
package.path = requirePath

-- Import required modules
local luaAPI = require("api")
local Helpers = luaAPI.Modules.Helpers

local function packScript(inputScriptPath, outputPath)
  local packedAST = luaAPI.Packer.PackScript(Helpers.readFile(inputScriptPath), scriptPath .. "../src/")
  local packedASTTokens = luaAPI.ASTToTokensConverter.ConvertToTokens(packedAST)
  local printedScript = luaAPI.Printer.TokenPrinter.PrintTokens(packedASTTokens)

  Helpers.writeFile(outputPath, printedScript)
end

packScript("src/api.lua", "LuaXen.lua")
packScript("src/lua.lua", "lua.lua")