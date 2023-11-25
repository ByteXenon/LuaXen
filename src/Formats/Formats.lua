

-- Export library functions *--
local insert = table.insert
local gmatch = string.gmatch
local unpack = (unpack or table.unpack)

--* Formats *--
local Formats = {}
Formats.formats = {
  reset = "\27[0m",

  -- Text Formats
  bold = "\27[1m",
  faint = "\27[2m",
  italic = "\27[3m",
  underline = "\27[4m",
  blinking = "\27[5m",
  blinking2 = "\27[6m",
  inverse = "\27[7m",
  invisible = "\27[8m",
  strikethrough = "\27[9m",

  -- Foreground text colors
  black = "\27[30m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  white = "\27[37m",

  -- Background colors
  bg_black = "\27[40m",
  bg_red = "\27[41m",
  bg_green = "\27[42m",
  bg_yellow = "\27[43m",
  bg_blue = "\27[44m",
  bg_magenta = "\27[45m",
  bg_cyan = "\27[46m",
  bg_white = "\27[47m",

  -- Cursor movement
  up     = function(n) return string.format("\27[%dA", n or 1) end,
  down   = function(n) return string.format("\27[%dB", n or 1) end,
  right  = function(n) return string.format("\27[%dC", n or 1) end,
  left   = function(n) return string.format("\27[%dD", n or 1) end,

  -- Cursor position
  set_cursor_position  	= function(x, y) return string.format("\027[%d;%dH", y or 1, x or 1) end,
  save_cursor_position 	= "\027[s",
  restore_cursor_position	= "\027[u",

  -- Screen clearing
  clear_screen_from_cursor_to_end  	= "\027[J",
  clear_screen_from_cursor_to_start 	= "\027[1J",
  clear_screen 						= "\027[2J",

  -- Line clearing
  clear_line_from_cursor_to_end  	= "\027[K",
  clear_line_from_cursor_to_start	= "\027[1K",
  clear_line 						= "\027[2K",

  -- Scrolling
  scroll_up  	= function(n) return string.format("\027[%dS", n or 1) end,
  scroll_down	= function(n) return string.format("\027[%dT", n or 1) end,

  -- Colors
  fg_rgb    	= function(r, g, b) return string.format("\027[38;2;%d;%d;%dm", r, g, b) end,
  bg_rgb    	= function(r, g, b) return string.format("\027[48;2;%d;%d;%dm", r, g, b) end,

  default_color 	= "\027[m"
}

function Formats.formatString(str)
	str = str:gsub(">%(([%w_]*)%)<", function(formatCode)
    local format = Formats.formats[formatCode]
    if type(format) == "string" then
      return format
    end
  end)

  str = str:gsub(">%((([%w_]*)%(%d+[%s*,%d+]*%))%)<", function(fullFormatCode, formatCodeName)
    local formatFunction = Formats.formats[formatCodeName]
    if type(formatFunction) ~= "function" then return end

    local arguments = {}
    for argument in fullFormatCode:sub(#formatCodeName + 2, -2):gmatch("%d+") do
      insert(arguments, argument)
    end
    return formatFunction(unpack(arguments))
  end)
	return str
end

return Formats