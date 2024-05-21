--[[
  Name: Compression.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-05
--]]

--* Dependencies *--
local Conversion = require("Crypt/Conversion/Conversion")

--* Imports *--
local insert = table.insert
local concat = table.concat
local char = string.char
local sub = string.sub
local toBase36 = Conversion.toBase36

--* Compression *--
local Compression = {}

--- Lempel-Ziv-Welch decompression function
-- @description Decodes a string that was encoded using the Lempel-Ziv-Welch compression algorithm.
-- @param compressedString The string to be decompressed.
-- @return The decompressed string.
function Compression.lzwDecompress(compressedString)
  local currentChar, nextChar, output = "", "", {}
  local dictionarySize = 256
  local dictionary = {}
  for i = 0, dictionarySize - 1 do
    dictionary[i] = char(i)
  end

  local stringIndex = 1
  local function readNextCode()
    local codeLength = tonumber(sub(compressedString, stringIndex, stringIndex), 36)
    stringIndex = stringIndex + 1
    local code = tonumber(sub(compressedString, stringIndex, stringIndex + codeLength - 1), 36)
    stringIndex = stringIndex + codeLength
    return code
  end

  currentChar = char(readNextCode())
  output[1] = currentChar
  while stringIndex < #compressedString do
    local nextCode = readNextCode()
    nextChar = dictionary[nextCode] or (currentChar .. sub(currentChar, 1, 1))
    dictionary[dictionarySize] = currentChar .. sub(nextChar, 1, 1)
    output[#output + 1], currentChar, dictionarySize = nextChar, nextChar, dictionarySize + 1
  end

  return concat(output)
end

--- Lempel-Ziv-Welch compression function
-- @description Encodes a string using the Lempel-Ziv-Welch compression algorithm.
-- @param inputString The string to be compressed.
-- @return The compressed string.
function Compression.lzwCompress(inputString)
  local dictionarySize = 256
  local dictionary = {}
  for i = 0, dictionarySize - 1 do
    dictionary[char(i)] = i
  end

  local currentChar = sub(inputString, 1, 1)
  local nextChar = ""
  local output = {}
  for i = 2, #inputString do
    nextChar = sub(inputString, i, i)
    if not dictionary[currentChar .. nextChar] then
      local code = dictionary[currentChar]
      insert(output, toBase36(#toBase36(code)))
      insert(output, toBase36(code))
      dictionary[currentChar .. nextChar] = dictionarySize
      currentChar = nextChar
      dictionarySize = dictionarySize + 1
    else
      currentChar = currentChar .. nextChar
    end
  end
  if currentChar ~= "" then
    local code = dictionary[currentChar]
    local codeLength = #toBase36(code)
    insert(output, toBase36(codeLength))
    insert(output, toBase36(code))
  end

  return concat(output)
end

return Compression