--* Export library functions *--
local sub = string.sub
local floor = math.floor
local concat = table.concat
local insert = table.insert
local random = math.random

math.randomseed(os.time())

local function numberToBase(value, base, len)
  local b = {
    "0","1","2","3","4","5","6","7","8","9",
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z"
  }
  local r = ""
  while value > 0 do
    local nval = b[value % base + 1]
    r = nval .. r
    value = floor(value / base)
  end
  if len then r = string.rep("0", len - #r) .. r end

  return r
end

local function randomlyUpperChars(str)
  local newStr = {}
  for char in str:gmatch(".") do
    if char:match("%a") then
      if random(0, 1) == 1 then insert(newStr, char:upper())
      else insert(newStr, char) end
    else
      insert(newStr, char)
    end
  end
  return concat(newStr)
end

local function decode(a)
  local instructionTb = {}
  local constantTb = {}
  -- I'm really happy that I don't need to come up with
  -- bs variable names, who cares anyway. (-:
  local i = 1
  --    xx      xx        xx        xx        xx
  --  |base| |opname| |a_param| |b_param| |c_param|
  -- xx = 00 .. zz

  while (i) do
    if a:sub(i, i + 2):lower() == "xzq" then
      -- No way it is a real instruction.
      -- Stop, because it's the constant sector
      break
    end
    -- enc_t is a variable to make it harder to decode instructions
    -- and/or use a frequency analysis method.
    -- enc_t stores the base of opcode and params
    -- 28 < enc_t < 36
    -- numberToBase(((random_encd - 1)^2 - 1) - op, random_encd - 1, 2)
    -- numberToBase((36^2 - 1) - random_encd, 36, 2)

    local enc_t = tonumber(a:sub(i, i), 36)
    i = i + 1;
    local _op = tonumber(a:sub(i, i + 1), enc_t)
    -- A random value of 67 equals 0, and vice versa
    _op = (_op == 67 and 0) or (_op == 0 and 67) or _op
    i = i + 2;
    -- Same as above
    local _a = tonumber(a:sub(i, i + 1), enc_t)
    _a = (_a == 42 and 0) or (_a == 0 and 42) or _a
    i = i + 2;
    -- Same as above
    local _b = tonumber(a:sub(i, i + 1), enc_t)
    _b = (_b == 69 and 0) or (_b == 0 and 69) or _b
    i = i + 2;
    -- Same as above, god I'm lazy
    local _c = tonumber(a:sub(i, i + 1), enc_t)
    _c = (_c == 12 and 0) or (_b == 0 and 12) or _c
    i = i + 2;
    table.insert(instructionTb, {_op, _a, _b, _c})
  end
  
  i = i + 3
  while true do
    if a:sub(i, i) == "0" then break end
    -- max constant length: 1296 (36^2 because all constants are the length of 1 or more)
    -- more equals overflow, but we still don't care.
    local constLen = tonumber(a:sub(i, i + 1), 36)
    i = i + 2
    local constType = tonumber(a:sub(i, i + 1), 36)
    i = i + 2
    if constType == 1 then -- Number
      insert(constantTb, tonumber(g:sub(i, i + constLen)))
    elseif constType == 2 then -- String
      insert(constantTb, tostring(g:sub(i, i + constLen)))
    end
    i = i + (constLen + 1)
  end
  return instructionTb, constantTb
end

local function encodeInstruction(instruction)
  local random_encd = math.random(28, 36)
  local op, a, b, c = unpack(instruction)
  if op == 67 then op = 0
  elseif op == 0 then op = 67 end
  if a == 42 then a = 0
  elseif a == 0 then a = 42 end
  if b == 69 then b = 0
  elseif b == 0 then b = 69 end
  if c == 12 then c = 0
  elseif c == 0 then c = 12 end

  -- Thou shall not question the code below, there be dragons.
  local b_random_encd = numberToBase((36^2 - 1) - random_encd, 36, 2)
  op = numberToBase(((random_encd - 1)^2 - 1) - op, random_encd - 1, 2)
  a = numberToBase(((random_encd - 2)^2 - 1) - a, random_encd - 2, 2)
  b = numberToBase(((random_encd - 3)^2 - 1) - b, random_encd - 3, 2)
  c = numberToBase(((random_encd - 4)^2 - 1) - c, random_encd - 4, 2)
  return randomlyUpperChars(concat({ b_random_encd, op, a, b, c }))
end
local function encodeConstant(value)
  local valueType = type(value)
  local valueLen = #tostring(value) - 1
  return numberToBase((valueType == "string" and 2) or 1, 36, 2) .. numberToBase(valueLen, 36, 2) .. tostring(value)
end
local function encodeLuaState(state)
  local instructions = state.instructions
  local constants = state.constants
  local instructionsStrs = {}
  local constantsStrs = {}
  for _, instr in ipairs(instructions) do
    insert(instructionsStrs, encodeInstruction(instr))
  end
  for _, const in ipairs(constants) do
    insert(constantsStrs, encodeConstant(const))
  end

  return "LuaXen|" .. concat(instructionsStrs) .. randomlyUpperChars("xzq") .. concat(constantsStrs) .. "0"
end

local constants = {
  "hello, world!",
  "print"
}
local instructions = {
  { 1, 2, 3, 4   },
  { 4, 3, 2, 1   },
  { 1, 69, 42, 0 }
}
local state = { constants = constants, instructions = instructions }
decode(encodeLuaState(state))

-- decode("g00000000a")