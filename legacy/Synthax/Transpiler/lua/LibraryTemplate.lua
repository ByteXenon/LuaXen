--[[
  Name: LibraryTemplate.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

local Template = [==[
--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Something/Something")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local Class = Helpers.NewClass
local insert = table.insert
local concat = table.concat

--* Parser *--
local Parser = {};
function Parser:new(charStream)
  local ParserInstance = {}

  local charStream = charStream
  local curCharPos = 1
  local curChar = charStream[curCharPos] 

  function ParserInstance:peek(n)
    return charStream[curCharPos + (n or 1)]
  end
  function ParserInstance:consume(n)
    curCharPos = curCharPos + (n or 1)
    curChar = charStream[curCharPos]
    return curChar
  end
  function ParserInstance:isBlank(char)
    local char = char or curChar
    return char:match("%s")
  end;
  function ParserInstance:isKeyword(char)
    local char = char or curChar
    return char:match("%a")
  end
  function ParserInstance:consumeBlank()
    local c = {curChar}
    while self:isBlank() and self:consume() do insert(c, curChar) end
    return concat(c)
  end
  function ParserInstance:consumeKeyword()
    local c = {curChar}
    while self:isKeyword() and self:consume() do insert(c, curChar) end
    return concat(c)
  end
  function ParserInstance:consumeCharSequence(chars)
    local len = #chars - 1
    local tb = {curChar}
    for _ = 1, len do
      insert(tb, self:consume())
    end

    return concat(tb) == chars
  end
  function ParserInstance:try(func, ...)
    local oldPosition = curCharPos
    
    local returnValue = func(self, ...)
    if not returnValue then
      curCharPos = oldPosition
      curChar = charStream[curCharPos]
    end
    return returnValue
  end

{0}

  return ParserInstance
end
]==]

return Template