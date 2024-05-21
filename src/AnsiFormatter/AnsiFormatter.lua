--[[
  Name: AnsiFormatter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Imports *--
local insert = table.insert
local unpack = (unpack or table.unpack)

--* Constants *--
local ESCAPE_CODES = {
  RESET = "\27[0m",
  BOLD = "\27[1m",
  FAINT = "\27[2m",
  ITALIC = "\27[3m",
  UNDERLINE = "\27[4m",
  BLING = "\27[5m",
  REVERSE = "\27[7m",
  HIDDEN = "\27[8m",
  STRIKETHROUGH = "\27[9m",
  BLACK = "\27[30m",
  RED = "\27[31m",
  GREEN = "\27[32m",
  YELLOW = "\27[33m",
  BLUE = "\27[34m",
  MAGENTA = "\27[35m",
  CYAN = "\27[36m",
  WHITE = "\27[37m",
  BG_BLACK = "\27[40m",
  BG_RED = "\27[41m",
  BG_GREEN = "\27[42m",
  BG_YELLOW = "\27[43m",
  BG_BLUE = "\27[44m",
  BG_MAGENTA = "\27[45m",
  BG_CYAN = "\27[46m",
  BG_WHITE = "\27[47m",

  CLEAR_LINE = "\27[2K",
  -- Go to the start of the line
  START_LINE = "\27[0G",
  CLEAR_AFTER_CURSOR = "\27[J",
}

local ADVANCED_ESCAPE_CODES = {
  RGB_COLOR = "\27[38;2;%d;%d;%dm",
  BG_RGB_COLOR = "\27[48;2;%d;%d;%dm",
  CURSOR_UP = "\27[%dA",
  CURSOR_DOWN = "\27[%dB",
  CURSOR_FORWARD = "\27[%dC",
  CURSOR_BACK = "\27[%dD",
  CURSOR_NEXT_LINE = "\27[%dE",
  CURSOR_PREVIOUS_LINE = "\27[%dF",
  CURSOR_HORIZONTAL_ABSOLUTE = "\27[%dG",
  CURSOR_POSITION = "\27[%d;%dH",
  ERASE_DISPLAY = "\27[%dJ",
  ERASE_LINE = "\27[%dK",
  SCROLL_UP = "\27[%dS",
  SCROLL_DOWN = "\27[%dT"
}

--* AnsiFormatter *--
local AnsiFormatter = {}
AnsiFormatter.escapeCodes = ESCAPE_CODES
AnsiFormatter.advancedEscapeCodes = ADVANCED_ESCAPE_CODES

--- Formats a string according to the formatting escape codes in it.
-- @param string The string to format.
-- @return The formatted string.
-- @example "Hello %{BOLD}%World%{RESET}%!" -> "Hello \27[1mWorld\27[0m!"
function AnsiFormatter.formatSimpleString(string)
  return (string:gsub("%%{([%w_]+)}%%", function(formattingCode)
    assert(ESCAPE_CODES[formattingCode], "Invalid formatting code.")
    return ESCAPE_CODES[formattingCode]
  end))
end

--- Formats a string according to the advanced formatting escape codes in it.
-- @param string The string to format.
-- @return The formatted string.
-- @example "Hello %{RGB_COLOR:255:0:0:}%World!" -> "Hello \27[38;2;255;0;0mWorld!"
function AnsiFormatter.formatAdvancedString(string)
  return (string:gsub("%%{([%w_]+):([^}]+)}%%", function(formattingCode, parametersString)
    assert(ADVANCED_ESCAPE_CODES[formattingCode], "Invalid advanced formatting code.")

    local parameters = {}
    for parameter in parametersString:gmatch("[^:]+") do
      insert(parameters, tonumber(parameter))
    end

    return ADVANCED_ESCAPE_CODES[formattingCode]:format(unpack(parameters))
  end))
end

--- Formats both normal and advanced formatting escape codes in a string.
-- @param string The string to format.
-- @return The formatted string.
function AnsiFormatter.formatString(string)
  return (AnsiFormatter.formatAdvancedString(AnsiFormatter.formatSimpleString(string)))
end

--- Formats a substring with the given formatting code. Does not reset the formatting at the end.
-- @param substring The substring to format.
-- @param formattingCode The formatting code to use.
-- @return The formatted substring.
function AnsiFormatter.formatSubstringWithoutReset(substring, formattingCode)
  assert(ESCAPE_CODES[formattingCode], "Invalid formatting code.")
  return ESCAPE_CODES[formattingCode] .. substring
end

--- Formats a substring with the given formatting code. Resets the formatting at the end.
-- @param substring The substring to format.
-- @param formattingCode The formatting code to use.
-- @return The formatted substring.
function AnsiFormatter.formatSubstring(substring, formattingCode)
  assert(ESCAPE_CODES[formattingCode], "Invalid formatting code.")
  return ESCAPE_CODES[formattingCode] .. substring .. AnsiFormatter.escapeCodes.RESET
end

--- Formats a substring with the given advanced formatting code, and the given parameters. Does not reset the formatting at the end.
-- @param substring The substring to format.
-- @param formattingCode The advanced formatting code to use.
-- @param ... The parameters to use in the formatting code.
-- @return The formatted substring.
function AnsiFormatter.formatAdvancedSubstringWithoutReset(substring, formattingCode, ...)
  assert(ADVANCED_ESCAPE_CODES[formattingCode], "Invalid advanced formatting code.")
  return ADVANCED_ESCAPE_CODES[formattingCode]:format(...) .. substring
end

--- Formats a substring with the given advanced formatting code, and the given parameters. Resets the formatting at the end.
-- @param substring The substring to format.
-- @param formattingCode The advanced formatting code to use.
-- @param ... The parameters to use in the formatting code.
-- @return The formatted substring.
function AnsiFormatter.formatAdvancedSubstring(substring, formattingCode, ...)
  assert(ADVANCED_ESCAPE_CODES[formattingCode], "Invalid advanced formatting code.")
  return ADVANCED_ESCAPE_CODES[formattingCode]:format(...) .. substring .. AnsiFormatter.escapeCodes.RESET
end

return AnsiFormatter