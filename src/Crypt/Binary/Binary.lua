--[[
  Name: Binary.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-06
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local concat = table.concat
local floor = math.floor
local abs = math.abs

local pow = math.pow
local frexp = math.frexp
local ldexp = math.ldexp

local char = string.char
local byte = string.byte
local sub = string.sub

--* Binary *--
local Binary = {}

function Binary.bitXOR(num1, num2)
  local bitValue, result = 1, 0
  while num1 > 0 and num2 > 0 do
    local bit1, bit2 = num1 % 2, num2 % 2
    if bit1 ~= bit2 then
      result = result + bitValue
    end
    num1, num2, bitValue = (num1 - bit1) / 2, (num2 - bit2) / 2, bitValue * 2
  end
  if num1 < num2 then
    num1 = num2
  end
  while num1 > 0 do
    local bit = num1 % 2
    if bit > 0 then
      result = result + bitValue
    end
    num1, bitValue = (num1 - bit) / 2, bitValue * 2
  end

  return result
end

function Binary.extractBits(number, startPos, endPos)
  if endPos then
    local bitRange = (number / 2 ^ (startPos - 1)) % 2 ^ ((endPos - 1) - (startPos - 1) + 1)
    return bitRange - bitRange % 1
  end
  local bitPos = 2 ^ (startPos - 1)
  return (number % (bitPos + bitPos) >= bitPos) and 1 or 0
end

function Binary.readOneByte(inputString, index)
  local byte1 = byte(inputString, index, index)
  return byte1
end

function Binary.readTwoBytes(inputString, index)
  local byte1, byte2 = byte(inputString, index, index + 1)
  return (byte2 * 256) + byte1
end

function Binary.readFourBytes(inputString, index)
  local byte1, byte2, byte3, byte4 = byte(inputString, index, index + 3)
  return (byte4 * 16777216) + (byte3 * 65536) + (byte2 * 256) + byte1
end

function Binary.readDouble(inputString, index)
  local lowerPart = Binary.readFourBytes()
  index = index + 4
  local upperPart = Binary.readFourBytes()
  local sign = 1
  local mantissa = (Binary.extractBits(upperPart, 1, 20) * (2 ^ 32)) + lowerPart
  local exponent = Binary.extractBits(upperPart, 21, 31)
  local signBit = ((- 1) ^ Binary.extractBits(upperPart, 32))
  if (exponent == 0) then
    if (mantissa == 0) then
      return signBit * 0
    else
      exponent = 1
      sign = 0
    end
  elseif (exponent == 2047) then
    return (mantissa == 0) and (signBit * (1 / 0)) or (signBit * (0 / 0))
  end
  return ldexp(signBit, exponent - 1023) * (sign + (mantissa / (2 ^ 52)))
end

function Binary.readString(inputString, length, index)
  local resultString
  if (not length) then
    length = readFourBytes()
    if (length == 0) then
      return ''
    end
  end
  resultString = sub(inputString, index, index + length - 1)
  index = index + length
  local charTable = {}
  for i = 1, #resultString do
    charTable[i] = char(byte(sub(resultString, i, i)))
  end

  return concat(charTable), index
end

function Binary.makeOneByteBigEndian(number)
  return char(number)
end

function Binary.makeTwoBytesBigEndian(number)
  local byte1 = number % 256
  local byte2 = floor(number / 256)
  return char(byte2) .. char(byte1)
end

function Binary.makeFourBytesBigEndian(number)
  local byte1 = number % 256
  number = floor(number / 256)
  local byte2 = number % 256
  number = floor(number / 256)
  local byte3 = number % 256
  number = floor(number / 256)
  local byte4 = number
  return char(byte4) .. char(byte3) .. char(byte2) .. char(byte1)
end

function Binary.makeEightBytesBigEndian(number)
  local lowerPart = number % 4294967296
  local upperPart = floor(number / 4294967296)
  return Binary.makeFourBytesBigEndian(lowerPart) .. Binary.makeFourBytesBigEndian(upperPart)
end

--// Little Endian //--

function Binary.makeOneByteLittleEndian(number)
  return char(number % 256)
end

function Binary.makeTwoBytesLittleEndian(number)
  local byte1 = number % 256
  number = floor(number / 256)
  local byte2 = number % 256
  return char(byte1) .. char(byte2)
end

function Binary.makeFourBytesLittleEndian(number)
  local byte1 = number % 256
  number = floor(number / 256)
  local byte2 = number % 256
  number = floor(number / 256)
  local byte3 = number % 256
  number = floor(number / 256)
  local byte4 = number % 256
  return char(byte1) .. char(byte2) .. char(byte3) .. char(byte4)
end

function Binary.makeEightBytesLittleEndian(number)
  local byte1 = number % 256
  number = math.floor(number / 256)
  local byte2 = number % 256
  number = math.floor(number / 256)
  local byte3 = number % 256
  number = math.floor(number / 256)
  local byte4 = number % 256
  number = math.floor(number / 256)
  local byte5 = number % 256
  number = math.floor(number / 256)
  local byte6 = number % 256
  number = math.floor(number / 256)
  local byte7 = number % 256
  number = math.floor(number / 256)
  local byte8 = number % 256
  return string.char(byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8)
end

function Binary.makeDoubleLittleEndian(number)
  local signBit = (number < 0 and 1) or 0
  number = abs(number)

  local mantissa, exponent = frexp(number)
  if number == 0 then -- Zero
    exponent = 0
    mantissa = 0
  elseif number == 1/0 then -- Infinity
    exponent = 2047
    mantissa = 0
  elseif number ~= number then -- NaN
    exponent = 2047
    mantissa = 1
  else -- Normalized number
    exponent = exponent + 1022
    mantissa = (mantissa * 2 - 1) * pow(2, 52)
  end

  local upperPart = signBit * (2^31) + exponent * (2^20) + floor(mantissa / (2^32))
  local lowerPart = mantissa % (2^32)

  return Binary.makeFourBytesLittleEndian(lowerPart) .. Binary.makeFourBytesLittleEndian(upperPart)
end

function Binary.makeStringLittleEndian(inputString)
  local length = #inputString
  local charTable = {}
  for i = 1, length do
    charTable[i] = char(byte(sub(inputString, i, i)))
  end
  return Binary.makeFourBytesLittleEndian(length) .. concat(charTable)
end


return Binary