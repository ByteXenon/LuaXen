--[[
  Name: TokenFactory.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* TokenFactory *--
local TokenFactory = {}

function TokenFactory.createIdentifierToken(value)
  return { TYPE = "Identifier", Value = value }
end
function TokenFactory.createStringToken(value)
  return { TYPE = "String", Value = value }
end
function TokenFactory.createNumberToken(value)
  return { TYPE = "Number", Value = value }
end
function TokenFactory.createCharacterToken(value)
  return { TYPE = "Character", Value = value }
end

return TokenFactory