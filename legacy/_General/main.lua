--[[
  Name: main.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/??/XX
--]]

local Helpers = require("Helpers/Helpers")

local insert = table.insert

local i=insert;
local function strToTable(s)local t={}for c in(s:gmatch('.'))do i(t,c)end return(t)end

local function tokenize(str)
  local stream = strToTable(str)
  local charIndex = 1
  local curChar = stream[1]

  local function peek(n)
    return stream[charIndex + (n or 1)] or "\0"
  end
  local function consume(n)
    charIndex = charIndex + (n or 1)
    curChar = stream[charIndex] or "\0"
    return curChar
  end

  local function isIdentifier()
    return curChar:match("[_%a]")
  end
  local function consumeIdentifier()
    local identifier = {}
    repeat
      insert(identifier, curChar)
    until not (peek():match("[_%a%d]") and consume())
    return identifier
  end
  
  local function isNumber()
    return curChar:match("%d") or (curChar == "." and peek():match("%d"))
  end
  local function consumeNumber()
    local number = {}
    local point = false
    local scientificExpression = false
    
    repeat
      if curChar == "e" then
        scientificExpression = true
        point = true
      elseif curChar == "." then
        point = true
      end

      insert(number, curChar)
    until not ((peek():match("%d")or((peek()=="."and not point)or(peek()=="e"and not scientificExpression)))and consume())
    return number
  end

  local function isString()
    return (curChar == "'" or curChar == '"')
  end
  local function readString()
    local closingQuote = curChar
    local newString = {}
    consume()
    while curChar ~= closingQuote do
    end
  end

  local function run()
    local tokens = {}
    while curChar ~= "\0" do
      if curChar == " " or curChar == "\n" or curChar == "\t" then  
      elseif isIdentifier() then
        insert(tokens, { TYPE = "Identifier", consumeIdentifier() })
      elseif isNumber() then
        insert(tokens, { TYPE = "Number", consumeNumber() })
      else
        insert(tokens, { Type = "Character", curChar })
      end
      consume()
    end

    return tokens
  end

  return run()
end

Helpers.PrintTable(tokenize("hello.23e5+2"))