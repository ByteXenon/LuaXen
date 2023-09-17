--[[
  Name: ParserBuilder.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/ParserBuilder/ParserBuilder")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local insert = table.insert
local concat = table.concat
local StringToTable = Helpers.StringToTable
local TableFind = Helpers.TableFind

local ParserBuilder = {}
function ParserBuilder:clone()
  local ParserBuilderInstance = {};

  function ParserBuilderInstance:peekRange(n, m)
    local a = {}
    for i = n, m do
      insert(a, self.charStream[self.curCharPos + i])
    end
    return a
  end;
  function ParserBuilderInstance:consumeRange(n, m)
    self:consume(self.curCharPos + m)
    return self:peekRange(n, m)
  end;

  function ParserBuilderInstance:expectChars(...)
    local expectedChars = {...}
    local curChar = self.curChar

    if TableFind(expectedChars, curChar) then
      self:consume()
      return curChar
    end
    error(("Error: Expected one of characters: %s, got: %s"):format(
        concat(expectedChars, ", "), curChar)
    )
  end;

  function ParserBuilderInstance:readUntil(condition)
    local result = {}
    repeat
      insert(result, self.curChar)
      self:consume()
    until not (self.curChar and condition(self.curChar))

    return concat(result, "")
  end;
  readWhile = function(self, condition, statement)
    local result = {}
    local condition = (condition or function()
      return true
    end)
    local statement = (statement or function()
      return self.curChar
    end)

    while self.curChar and condition() do
      local returnResult = statement()
      if not returnResult then break end

      insert(result, returnResult)
      self:consume()
    end

    return concat(result, "")
  end;
  readWhileChar = function(self, targetChar)
    return self:readWhile(function()
      return self.curChar == targetChar
    end)
  end;
  readWhileNotString = function(self, targetString)
    local stringTb = StringToTable(targetString)
    local stringLen = #targetString
    local matchedIndex = 1;
    
    local returnString = self:readWhile(function()
      if stringTb[matchedIndex] == self.curChar then
        if matchedIndex == stringLen then
          return false
        end
        matchedIndex = matchedIndex + 1
      else
        matchedIndex = 1
      end

      return true
    end)
    return returnString:sub(0, -stringLen)
  end;


  consumeIdentifier = function(self)
    local identifier = {self.curChar}
    while self:peek() and self:peek():match("[%d%a_]") do
      insert(identifier, self:consume())
    end
    return concat(identifier)
  end;
  consumeDigit = function(self)

    local digit = {}
    while self.curChar do
      insert(digit, self.curChar)
      if self:peek() and self:isDigit(self:peek()) then
        self:consume()
      else
        break
      end;
    end

    return concat(digit)
  end;

  consumeWhitespace = function(self)
    local t = self:readWhile(function()
      return self:isWhitespace(self.curChar)
    end)
    self:consume(-1)
    return t
  end;
  consumeOptionalWhitespace = function(self)
    if self:isWhitespace() then self:consumeWhitespace() self:consume() end
  end;
  isWhitespace = function(self, char)
    local char = char or self.curChar
    return char:match("[%s]")
  end;
  isIdentifier = function(self, char)
    local char = char or self.curChar
    return char:match("[%a_]")
  end;
  isDigit = function(self, char)
    local char = char or self.curChar
    return char:match("%d")
  end;
}

return ParserBuilder