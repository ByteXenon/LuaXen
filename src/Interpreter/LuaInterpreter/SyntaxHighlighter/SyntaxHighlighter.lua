--[[
  Name: SyntaxHighlighter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/SyntaxHighlighter/SyntaxHighlighter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Formats = ModuleManager:loadModule("Formats/Formats")
local Themes = ModuleManager:loadModule("Interpreter/LuaInterpreter/SyntaxHighlighter/themes/themes")

--* Export library functions *--
local concat = table.concat
local insert = table.insert

--* SyntaxHighlighter *--
local SyntaxHighlighter = {}
function SyntaxHighlighter:new(tokens, theme)
  local SyntaxHighlighterInstance = {}
  SyntaxHighlighterInstance.tokens = tokens
  SyntaxHighlighterInstance.theme = Themes[theme or "h4x"]

  function SyntaxHighlighterInstance:getFormattedTokens()
    local strings = {} -- It's a table because we don't want to
                      -- ... use expensive concat operations for each token.
    local currentTokenIndex = 1
    while true do
      local currentToken = self.tokens[currentTokenIndex]
      if not currentToken then break end
      local tokenType, tokenValue = currentToken.TYPE, tostring(currentToken.Value)
      local strToFormat = (self.theme[tokenType] or "") .. tokenValue .. ">(reset)<"
      local formattedStr = Formats.formatString(strToFormat)
      insert(strings, formattedStr)
      currentTokenIndex = currentTokenIndex + 1
    end

    return concat(strings)
  end

  return SyntaxHighlighterInstance
end

return SyntaxHighlighter