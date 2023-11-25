--[[
  Name: TokenFactory.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* TokenFactory *--
local TokenFactory = {}

function TokenFactory.createConstantToken(value)
  return { TYPE = "Constant", Value = value }
end
function TokenFactory.createParenthesesToken(value)
  return { TYPE = "Parentheses", Value = value }
end
function TokenFactory.createOperatorToken(value)
  return { TYPE = "Operator", Value = value }
end

return TokenFactory