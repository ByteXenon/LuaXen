--[[
  Name: Lexer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Lexer/Lexer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local FormattedError = Helpers.FormattedError
local GetLines = Helpers.GetLines
local insert = table.insert
local concat = table.concat

-- * Lexer * --
local Lexer = {};
function Lexer:new(str)
  local LexerInstance = {}

  LexerInstance.charStream = StringToTable(str)
  LexerInstance.curCharPos = 1;
  LexerInstance.curChar = LexerInstance.charStream[LexerInstance.curCharPos]
  LexerInstance.tokens = {}

  function LexerInstance:updateCurChar()
    self.curChar = self.charStream[self.curCharPos]
  end
  function LexerInstance:peek()
    return self.charStream[self.curCharPos + 1]
  end;
  function LexerInstance:consume()
    self.curCharPos = self.curCharPos + 1
    self:updateCurChar()
    return self.curChar
  end;

  function LexerInstance:addToken(value, type)
    insert(self.tokens, { TYPE = type, Value = value })
  end

  function LexerInstance:isKeyword()
    return self.curChar:match("[%a_]")
  end
  function LexerInstance:consumeKeyword()
    local keyword = {}
    repeat
      insert(keyword, self.curChar)
    until not (self:peek() and self:peek():match("[%a%d_]") and self:consume())
    return concat(keyword)
  end;


  function LexerInstance:isNumber()
    local nextChar = self:peek()
    return self.curChar:match("%d") or (self.curChar == "-" and nextChar and nextChar:match("%d"))
  end;
  function LexerInstance:consumeNumber()
    local number = {self.curChar}
    while self:peek() and self:peek():match("%d") do
      insert(number, self:consume())
    end
    return concat(number)
  end

  function LexerInstance:isComment()
    return self.curChar == ";"
  end;
  function LexerInstance:consumeComment()
    local comment = {}
    while self:peek() ~= "\n" do
      insert(comment, self:consume())
    end
    return concat(comment)
  end;

  function LexerInstance:isString()
    return self.curChar == "'" or self.curChar == '"'
  end;
  function LexerInstance:consumeString()
    local openingQuote = self.curChar
    local newString = {}
    while self:consume() and self.curChar ~= openingQuote do
      insert(newString, self.curChar)
    end
    return concat(newString)
  end

  function LexerInstance:tokenize()
    local curChar = self.curChar
    while curChar do
      if curChar == " " or curChar == "\t" then
      elseif curChar == "\n" then
        self:addToken(nil, "END_OF_LINE")
      elseif curChar == ":" then
        self:addToken(nil, "COLON")
      elseif curChar == "{" then
        self:addToken(nil, "LEFT_BRACE")
      elseif curChar == "}" then
        self:addToken(nil, "RIGHT_BRACE")
      elseif self:isKeyword() then
        local keyword = self:consumeKeyword()
        if keyword == "true" or keyword == "false" then
          self:addToken(keyword, "BOOLEAN")
        else 
          self:addToken(keyword, "KEYWORD")
        end
      elseif self:isNumber() then
        self:addToken(self:consumeNumber(), "NUMBER")
      elseif self:isComment() then
        -- self:addToken(self:consumeComment(), "COMMENT")
        self:consumeComment()
      elseif self:isString() then
        self:addToken(self:consumeString(), "STRING")
      else
        self:addToken(curChar, "CHARACTER")
      end

      curChar = self:consume()
    end

    self:addToken(nil, "EOF")
    return self.tokens
  end;

  return LexerInstance
end;

return Lexer