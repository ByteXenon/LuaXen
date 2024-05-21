--[[
  Compiler self-hosting example.
  ==============================
  This example shows how we can execute the compiler from within the compiler itself.
  It parses, interprets and executes every single line of the compiler's source code.

  https://en.wikipedia.org/wiki/Self-hosting_(compilers)
--]]

-- Localize the path, so this file can be ran from anywhere
local scriptPath = (debug.getinfo(1).source:match("@?(.*/)") or "")
local requirePath = scriptPath .. "../src/?.lua"
local localPath = scriptPath .. "../src/"
package.path = requirePath

-- Import required modules
local luaAPI = require("api")

-- Hook into the require function, so we can run all the files through the compiler
local oldRequire = require
local cached = {}
_G.require = function(path)
  if (cached[path]) then
    return cached[path]
  end

  print("Compiling & Running: " .. path .. ".lua")
  local result = luaAPI.ASTExecutor.ExecuteScript(luaAPI.Modules.Helpers.readFile(localPath .. path .. ".lua"))
  cached[path] = result
  return result
end

-- Execute the compiler's handler file
luaAPI.ASTExecutor.ExecuteScript(luaAPI.Modules.Helpers.readFile(localPath .. "lua.lua"))

-- Restore the require function
_G.require = oldRequire