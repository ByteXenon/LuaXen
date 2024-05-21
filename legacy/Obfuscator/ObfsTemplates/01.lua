--[[
  Name: 01.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

-- "A simple embeded virtual machine
-- in an obfuscated code"
return (function(a, b, c, d, e, f, g)
  local function decode()
    local instructionTb = {}
    local constantTb = {}
    -- I'm really happy that I don't need to come up with
    -- stupid variable names, who cares anyway. (-:
    local i = 1
    while (i) do
      if a:sub(i, i) == "a" then
        -- No way it is a real instruction.
        -- Stop, because it's the constant sector
        break
      end
      -- enc_t is a variable to make it harder to decode instructions
      -- and/or use a frequency analysis method.
      -- enc_t stores the base of opcode and params
      -- 24 < enc_t < 36
      local enc_t = tonumber(a:sub(i, i), 36)
      i = i + 1;
      local op = tonumber(a:sub(i, i + 2), enc_t)
      -- A random value of 67 is equals 0
      -- 0 equals 67, what if we wanted 67? Well,
      -- It's 0 now.
      op = (op == 67 and 0) or op
      i = i + 3;
      local a = tonumber(a:sub(i, i + 2), enc_t)
      a = (a == 42 and 0) or a
      i = i + 3;
      local b = tonumber(a:sub(i, i + 2), enc_t)
      b = (b == 69 and 0) or b
      i = i + 3;
      local c = tonumber(a:sub(i, i + 2), enc_t)
      c = (c == 12 and 0) or b
      i = i + 3;
      table.insert(instructionTb, {op, a, b, c})
    end
    while true do
      if a:sub(i, i) == "0" then break end
      i = i + 1
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

  local pc = 0;
  local instructions, constants = decode()
  while true do
    
  end
end)("")