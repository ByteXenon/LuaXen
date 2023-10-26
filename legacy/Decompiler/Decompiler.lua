--[[
  Name: Decompiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("LuaState/LuaState")

--* Export library functions *--
local Class = Helpers.NewClass
local StringToTable = Helpers.StringToTable
local GetLines = Helpers.GetLines
local find = Helpers.FindTable
local insert = table.insert
local concat = table.concat
local byte = string.byte
local char = string.char
local rep = string.rep

-- * Decompiler * --
local Decompiler;
Decompiler = Class{
  __init__ = function(self, state, indentation)
    self.state = state

    self.decompiledProtos = {}
    for _, proto in ipairs(state.protos) do
      local newDecompiler = Decompiler(proto, 1)
      newDecompiler:run()
      local decompiledCode = newDecompiler:getCode()
      insert(self.decompiledProtos, decompiledCode)
    end

    self.indentation = indentation or 0
    self.instructionIndex = 1
    self.declaredRegisters = {}
    self.lines = {}
  end;
  increaseInstructionCounter = function(self, val)
    self.instructionIndex = self.instructionIndex + (val or 1)
  end;
  getCurrentInstruction = function(self)
    return self.state.instructions[self.instructionIndex]
  end;
  consumeInstruction = function(self)
    self:increaseInstructionCounter()
    return self:getCurrentInstruction()
  end;
  processConstant = function(self, constant)
    if type(constant) == "string" then
      return "'" .. constant .. "'"
    elseif type(constant) == "number" then
      return tostring(constant)
    end;
    return tostring(constant)
  end;
  processRegisterOrConstant = function(self, integer)
    local isConstant = integer < 0
    if isConstant then
      return self:processConstant(self.state.constants[-integer])
    else
      return ("Register_%d"):format(integer)
    end
  end;
  newLineOfCode = function(self, line)
    return (rep("  ", self.indentation or 0) .. line)
  end;
  addLineOfCode = function(self, table, line)
    insert(table, self:newLineOfCode(line))
  end;
  convertToExpression = function(self, table, OPName, A, B, C)
    
  end;
  processInstruction = function(self, table, OPName, A, B, C)
    local OPName, A, B, C = OPName, A, B, C
    if OPName == "LOADK" then
      local isRegisterDeclared = self.declaredRegisters[A]
      self.declaredRegisters[A] = true

      local constant = self:processConstant(self.state.constants[-B])
      local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s"
      self:addLineOfCode(table, formatString:format(A, constant))
    elseif OPName == "GETGLOBAL" then
      local isRegisterDeclared = self.declaredRegisters[A]
      self.declaredRegisters[A] = true

      local constant = self.state.constants[-B]--self:processConstant(self.state.constants[-B])
      local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s" --"Register_%d = getfenv()[%s]"
      self:addLineOfCode(table, formatString:format(A, constant))
    elseif OPName == "MOVE" then
      local isRegisterDeclared = self.declaredRegisters[A]
      self.declaredRegisters[A] = true

      local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = Register_%d"
      self:addLineOfCode(table, formatString:format(A, B))
    elseif OPName == "CALL" then -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
      local returnRegisters = {}
      for i = A, A + C - 2 do
        insert(returnRegisters, ("Register_%d"):format(i))
      end
      local arguments = {}
      for i = A + 1, A + B - 1 do
        insert(arguments, ("Register_%d"):format(i))
      end

      if #returnRegisters ~= 0 then
        return self:addLineOfCode(table,  ("%s = Register_%d(%s)"):format(concat(returnRegisters, ", "), A, concat(arguments, ", ")) )
      end;
      return self:addLineOfCode(table, ("Register_%d(%s)"):format(A, concat(arguments, ", ")))
    elseif OPName == "GETTABLE" then -- self.Register[A] = self.Register[B][self.Constants[C] or self.Register[C]]
      local C = self:processRegisterOrConstant(C)

      local isRegisterDeclared = self.declaredRegisters[A]
      self.declaredRegisters[A] = true

      local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = Register_%d[%s]"
      self:addLineOfCode(table, formatString:format(A, B, C))
    elseif OPName == "CLOSURE" then
      self:addLineOfCode(table, ("local function Register_%d()"):format(A))
      for i, v in ipairs(GetLines(self.decompiledProtos[B + 1])) do
        self:addLineOfCode(table, v)
      end
      self:addLineOfCode(table, "end")
    -- R(A), R(A+1), ..., R(A+B-1) = vararg
    elseif OPName == "VARARG" then
      local registers = {}
      for i = A, A+B-1 do
        insert(registers, ("Registers_%d"):format(i))
      end
      return self:addLineOfCode(table, ("%s = ..."):format(concat(registers, ", ")))
    -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
    elseif OPName == "TEST" then
      local nextInstruction = self:consumeInstruction()
      local nextOPName, jumpLength = unpack(nextInstruction or {})
      if not (nextOPName == "JMP") then
        error("Invalid TEST instruction")
      end

      local instructionBlock1 = {}
      local instructionBlock2 = {}

      
      self.indentation = self.indentation + 1
      self:processInstructionsInRange(jumpLength - 1, instructionBlock1)
      self.indentation = self.indentation - 1

      local secondOPName, secondJumpLength = unpack(self:consumeInstruction())
      if not (secondOPName == "JMP") then
        error("Invalid TEST instruction")
      end
      
      -- it's "if" statement
      if secondJumpLength >= 0 then
        self.indentation = self.indentation + 1
        self:processInstructionsInRange(secondJumpLength, instructionBlock2)
        self.indentation = self.indentation - 1

        local condition = ("%s(Register_%d)"):format(B == 1 and "not " or "", A)
        self:addLineOfCode(table, ("if %s then"):format(condition))
        for i, v in ipairs(instructionBlock1) do insert(table, v) end
        self:addLineOfCode(table, "else")
        for i, v in ipairs(instructionBlock2) do insert(table, v) end
        self:addLineOfCode(table, "end")
      else -- it's "while" statement because it jumps back

      end -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
    elseif OPName == "RETURN" then
      local registers = {}
      for i = A, A + B - 2 do
        insert(registers, ("Register_%d"):format(i))
      end
      self:addLineOfCode(table, ("return %s"):format(concat(registers, ", ")))
    else
      error(("Invalid opcode: %s"):format(OPName))
    end;
  end;
  processInstructionsInRange = function(self, range, tb)
    local tb = tb or self.lines
    for index = 1, range do
      local newInstruction = self:consumeInstruction()
      if not newInstruction then
        error("Invalid instruction range")
      end
      self:processInstruction(tb, unpack(newInstruction))
    end
  end;
  run = function(self)
    local lines = self.lines
    while (true) do
      local currentInstruction = self:getCurrentInstruction()
      if not currentInstruction then break end
      self:processInstruction(lines, unpack(currentInstruction))
      self:increaseInstructionCounter()
    end;
  end;
  getCode = function(self)
    return concat(self.lines, "\n")
  end;
}

return Decompiler