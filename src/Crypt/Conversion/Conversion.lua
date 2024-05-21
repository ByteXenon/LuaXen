--[[
  Name: Conversion.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-05
--]]

--* Constants *--
local BASE36_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

--* Conversion *--
local Conversion = {}

--- Converts a number to base 36
-- @description Converts a number to a base 36 string using the characters 0-9 and A-Z.
-- @param number The number to be converted.
-- @return The base 36 representation of the number as a string.
function Conversion.toBase36(number)
  if number == 0 then
    return "0"
  end

  local result = ""
  while number > 0 do
    local remainder = number % 36
    result = string.sub(BASE36_CHARS, remainder + 1, remainder + 1) .. result
    number = (number - remainder) / 36
  end
  return result
end

return Conversion