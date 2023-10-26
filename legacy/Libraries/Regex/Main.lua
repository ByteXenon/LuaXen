--[[
  Name: Main.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

--* Libraries *--
local Helpers = require("Helpers/Helpers")

--* Library object *--
local Regex = {}

--* Data *--
local Patterns = {
	["d"] = Helpers.RangesToChars({"0", "9"}),
	["a"] = Helpers.RangesToChars({"a", "z"}, {"A", "Z"}),
	["p"]
	
}

--* Functions *--
function Regex.Match(String, Pattern)
	
end
function Regex.CharMatch(Char, Pattern)
	
end

return Regex
