--[[
  Name: Crypt.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-05
--]]

local Binary = require("Crypt/Binary/Binary")
local Conversion = require("Crypt/Conversion/Conversion")
local Compression = require("Crypt/Compression/Compression")

--* Crypt *--
local Crypt = {
  Binary = Binary,
  Conversion = Conversion,
  Compression = Compression
}

return Crypt