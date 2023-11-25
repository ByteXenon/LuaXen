--[[
  Name: TokenFactory.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* TokenFactory *--
local TokenFactory = {}

function TokenFactory.createEOFToken()
  return { TYPE = "EOF" }
end
function TokenFactory.createNewLineToken()
  return { TYPE = "NewLine" }
end
function TokenFactory.createWhitespaceToken(value)
  return { TYPE = "Whitespace", Value = value }
end
function TokenFactory.createCommentToken(value)
    return { TYPE = "Comment", Value = value }
end
function TokenFactory.createNumberToken(value)
    return { TYPE = "Number", Value = value }
end
function TokenFactory.createConstantToken(value)
    return { TYPE = "Constant", Value = value }
end
function TokenFactory.createOperatorToken(value)
    return { TYPE = "Operator", Value = value }
end
function TokenFactory.createKeywordToken(value)
    return { TYPE = "Keyword", Value = value }
end
function TokenFactory.createIdentifierToken(value)
    return { TYPE = "Identifier", Value = value }
end
function TokenFactory.createCharacterToken(value)
    return { TYPE = "Character", Value = value }
end
function TokenFactory.createStringToken(value)
    return { TYPE = "String", Value = value }
end

return TokenFactory