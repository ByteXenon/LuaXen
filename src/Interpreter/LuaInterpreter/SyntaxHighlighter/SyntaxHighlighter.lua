--[[
  Name: SyntaxHighlighter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local AnsiFormatter = require("AnsiFormatter/AnsiFormatter")
local Themes = require("Interpreter/LuaInterpreter/SyntaxHighlighter/themes/themes")

--* Imports *--
local concat = table.concat
local formatString = AnsiFormatter.formatString

--* SyntaxHighlighterMethods *--
local SyntaxHighlighterMethods = {}

function SyntaxHighlighterMethods:getFormattedTokens()
  local currentTheme = self.theme
  local currentTokenIndex = 1
  local strings = {}

  while true do
    local currentToken = self.tokens[currentTokenIndex]
    if not currentToken then
      break
    end

    local tokenType = currentToken.TYPE
    local tokenValue = tostring(currentToken.Value)
    if tokenType == "VarArg" then
      tokenValue = "..."
    end

    local stringToFormat = (currentTheme[tokenType] or "") .. tokenValue .. "%{RESET}%"
    strings[currentTokenIndex] = stringToFormat
    currentTokenIndex = currentTokenIndex + 1
  end

  return formatString(concat(strings))
end

--* SyntaxHighlighter *--
local SyntaxHighlighter = {}
function SyntaxHighlighter:new(tokens, theme)
  local SyntaxHighlighterInstance = {}
  SyntaxHighlighterInstance.tokens = tokens
  SyntaxHighlighterInstance.theme = Themes[theme or "h4x"]

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if SyntaxHighlighterInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and SyntaxHighlighterInstance: " .. index)
      end
      SyntaxHighlighterInstance[index] = value
    end
  end

  -- Main
  inheritModule("SyntaxHighlighterMethods", SyntaxHighlighterMethods)

  return SyntaxHighlighterInstance
end

return SyntaxHighlighter