--[[
  Name: Instructions.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-12
--]]

-- Yep, all these instructions' implementations are local variables
-- We'll use the interpreter to grab their codeblocks and insert them into the VM

local function MOVE()
  stack[instruction[2]] = stack[instruction[3]]
end

local function LOADK()
  stack[instruction[2]] = instruction[3]
end

local function LOADBOOL()
  stack[instruction[2]] = (instruction[3] == 1)
  if instruction[4] == 1 then
    pc = pc + 1
  end
end

local function LOADNIL()
  for i = instruction[2], instruction[3] do
    stack[i] = nil
  end
end

local function GETUPVAL()
  stack[instruction[2]] = upvalues[instruction[3]]
end

local function GETGLOBAL()
  stack[instruction[2]] = ENV[instruction[3]]
end

local function GETTABLE() end
local function GETTABLE_AKBKC()
  stack[instruction[2]] = constants[instruction[3]][constants[instruction[4]]]
end
local function GETTABLE_AKBRC()
  stack[instruction[2]] = constants[instruction[3]][stack[instruction[4]]]
end
local function GETTABLE_ARBKC()
  stack[instruction[2]] = stack[instruction[3]][constants[instruction[4]]]
end
local function GETTABLE_ARBRC()
  stack[instruction[2]] = stack[instruction[3]][stack[instruction[4]]]
end

local function SETGLOBAL()
  ENV[instruction[2]] = stack[instruction[3]]
end

local function SETUPVAL()
  upvalues[instruction[2]] = stack[instruction[3]]
end

local function SETTABLE() end
local function SETTABLE_AKBKC()
  stack[instruction[2]][constants[instruction[3]]] = constants[instruction[4]]
end
local function SETTABLE_AKBRC()
  stack[instruction[2]][constants[instruction[3]]] = stack[instruction[4]]
end
local function SETTABLE_ARBKC()
  stack[instruction[2]][stack[instruction[3]]] = constants[instruction[4]]
end
local function SETTABLE_ARBRC()
  stack[instruction[2]][stack[instruction[3]]] = stack[instruction[4]]
end

local function NEWTABLE()
  stack[instruction[2]] = {}
end

local function SELF() end
local function SELF_AKBKC()
  stack[instruction[2] + 1] = constants[instruction[3]]
  stack[instruction[2]] = constants[instruction[3]][constants[instruction[4]]]
end
local function SELF_AKBRC()
  stack[instruction[2] + 1] = constants[instruction[3]]
  stack[instruction[2]] = constants[instruction[3]][stack[instruction[4]]]
end
local function SELF_ARBKC()
  stack[instruction[2] + 1] = stack[instruction[3]]
  stack[instruction[2]] = stack[instruction[3]][constants[instruction[4]]]
end
local function SELF_ARBRC()
  stack[instruction[2] + 1] = stack[instruction[3]]
  stack[instruction[2]] = stack[instruction[3]][stack[instruction[4]]]
end

local function ADD() end
local function ADD_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] + constants[instruction[4]]
end
local function ADD_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] + stack[instruction[4]]
end
local function ADD_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] + constants[instruction[4]]
end
local function ADD_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] + stack[instruction[4]]
end

local function SUB() end
local function SUB_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] - constants[instruction[4]]
end
local function SUB_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] - stack[instruction[4]]
end
local function SUB_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] - constants[instruction[4]]
end
local function SUB_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] - stack[instruction[4]]
end

local function MUL() end
local function MUL_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] * constants[instruction[4]]
end
local function MUL_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] * stack[instruction[4]]
end
local function MUL_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] * constants[instruction[4]]
end
local function MUL_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] * stack[instruction[4]]
end

local function DIV() end
local function DIV_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] / constants[instruction[4]]
end
local function DIV_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] / stack[instruction[4]]
end
local function DIV_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] / constants[instruction[4]]
end
local function DIV_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] / stack[instruction[4]]
end

local function MOD() end
local function MOD_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] % constants[instruction[4]]
end
local function MOD_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] % stack[instruction[4]]
end
local function MOD_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] % constants[instruction[4]]
end
local function MOD_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] % stack[instruction[4]]
end

local function POW() end
local function POW_AKBKC()
  stack[instruction[2]] = constants[instruction[3]] ^ constants[instruction[4]]
end
local function POW_AKBRC()
  stack[instruction[2]] = constants[instruction[3]] ^ stack[instruction[4]]
end
local function POW_ARBKC()
  stack[instruction[2]] = stack[instruction[3]] ^ constants[instruction[4]]
end
local function POW_ARBRC()
  stack[instruction[2]] = stack[instruction[3]] ^ stack[instruction[4]]
end

local function UNM()
  stack[instruction[2]] = -instruction[3]
end

local function NOT()
  stack[instruction[2]] = not instruction[3]
end

local function LEN()
  stack[instruction[2]] = #instruction[3]
end

local function CONCAT()
  local str = ""
  for i = instruction[3], instruction[4] do
    str = str .. stack[i]
  end
  stack[instruction[2]] = str
end

local function JMP()
  pc = pc + instruction[3]
end

local function EQ() end
local function EQ_AKBKC()
  if (constants[instruction[3]] == constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function EQ_AKBRC()
  if (constants[instruction[3]] == stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function EQ_ARBKC()
  if (stack[instruction[3]] == constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function EQ_ARBRC()
  if (stack[instruction[3]] == stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end

local function LT() end
local function LT_AKBKC()
  if (constants[instruction[3]] < constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LT_AKBRC()
  if (constants[instruction[3]] < stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LT_ARBKC()
  if (stack[instruction[3]] < constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LT_ARBRC()
  if (stack[instruction[3]] < stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end

local function LE() end
local function LE_AKBKC()
  if (constants[instruction[3]] <= constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LE_AKBRC()
  if (constants[instruction[3]] <= stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LE_ARBKC()
  if (stack[instruction[3]] <= constants[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end
local function LE_ARBRC()
  if (stack[instruction[3]] <= stack[instruction[4]]) ~= (instruction[2] == 1) then
    pc = pc + 1
  end
end

local function TEST()
  local _ = instruction[3] or instruction[4]
  if (not stack[instruction[2]]) == (_ == 1) then
    pc = pc + 1
  end
end

local function TESTSET()
  if (not not stack[instruction[3]]) == (instruction[4] == 1) then
    stack[instruction[2]] = stack[instruction[3]]
  else
    pc = pc + 1
  end
end

local function CALL()
  local args = {}

  local index = 1
  for i = instruction[2] + 1, instruction[2] + instruction[3] - 1 do
    args[index] = stack[i]
    index = index + 1
  end
  local results = {stack[instruction[2]](unpack(args))}

  index = 1
  for i = instruction[2], instruction[2] + instruction[4] - 2 do
    stack[i] = results[index]
    index = index + 1
  end
end

local function TAILCALL()
  local args = {}

  local index = 1
  for i = instruction[2] + 1, instruction[2] + instruction[3] - 1 do
    args[index] = stack[i]
    index = index + 1
  end
  return stack[instruction[2]](unpack(args))
end

local function RETURN()
  local results = {}

  local index = 1
  for i = instruction[2], instruction[2] + instruction[3] - 2 do
    results[index] = stack[i]
    index = index + 1
  end
  return unpack(results)
end

local function FORLOOP()
  local _ = stack[instruction[2]] + stack[instruction[2] + 2]
  if _ <= stack[instruction[2] + 1] then
    pc = pc + instruction[3]
    stack[instruction[2] + 3] = _
  end
  stack[instruction[2]] = _
end

local function FORPREP()
  stack[instruction[2]] = stack[instruction[2]] - stack[instruction[2] + 2]
  pc = pc + instruction[3]
end

local function TFORLOOP()
  local _ = instruction[3] or instruction[4]
  local table1 = {stack[instruction[2]](stack[instruction[2] + 1], stack[instruction[2] + 2])}
  local index = 1
  for i = instruction[2] + 3, instruction[2] + 2 + _ do
    stack[i] = table1[index]
    index = index + 1
  end
  if stack[instruction[2] + 3] ~= nil then
    stack[instruction[2] + 2] = stack[instruction[2] + 3]
  else
    pc = pc + 1
  end
end

local function SETLIST()
  local start = (instruction[4] - 1)
  local stop = start + instruction[3] - 1

  local table = stack[instruction[2]]
  for i = start, stop do
    table[i] = stack[instruction[2] + i - start + 1]
  end
end

local function CLOSE()

end

local function CLOSURE()
  local proto = protos[instruction[3]]
  local numUpvalues = proto[3]
  local upvalues = {}
  for i = 0, numUpvalues - 1 do
    pc = pc + 1
    local instruction = instructions[pc]
    local opcode = instruction[1]
    if opcode == 0 then -- OP_MOVE
      upvalues[i] = { stack, instruction[3] }
    elseif opcode == 4 then -- OP_GETUPVAL
      upvalues[i] = { upvalues, instruction[3] }
    end
  end
  local upvaluesMetatable = setmetatable({}, {
    __index = function(self, key)
      local upval = upvalues[key]
      return upval[1][upval[2]]
    end,
    __newindex = function(self, key, value)
      upvalues[key][1][upvalues[key][2]] = value
    end
  })

  stack[instruction[2]] = vmHandler(proto, upvaluesMetatable, ENV)
end

local function VARARG()
  local varargIndex = 1
  for i = instruction[2], instruction[2] + instruction[3] - 1 do
    stack[i] = vararg[varargIndex]
    varargIndex = varargIndex + 1
  end
end