--[[
  Name: themes.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/SyntaxHighlighter/themes/themes")

local function loadTheme(themeName)
  return ModuleManager:loadModule("Interpreter/LuaInterpreter/SyntaxHighlighter/themes/" .. themeName)
end

return {
  desert = loadTheme("desert"),
  forest = loadTheme("forest"),
  h4x = loadTheme("h4x")
}