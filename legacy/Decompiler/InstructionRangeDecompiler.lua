--[[
  Name: InstructionRangeDecompiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

-- TODO: Make a static analyzer which would generate a lot of useful stuff
--       like for example AST trees for instructions (if, while, etc.)

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
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
local InstructionRangeDecompiler = {}
function InstructionRangeDecompiler.new()
  local InstructionRangeDecompilerObject = {}

  function InstructionRangeDecompilerObject.decompile(self, instructions, constants, sharedDeclaredRegisters, decompiledProtos, min, max, indentation)
    local min = min or 1
    local max = max or #instructions

    self.declaredRegisters = {}
    for i, v in pairs(sharedDeclaredRegisters) do self.declaredRegisters[i] = v end
    self.decompiledProtos = decompiledProtos
    self.instructions = instructions
    self.constants = constants
    self.currentInstructionIndex = min
    self.shouldStop = false;
    self.indentation = indentation or 0;
    local lines = {}

    while self.currentInstructionIndex <= max and instructions[self.currentInstructionIndex] and not self.shouldStop do
      local instruction = instructions[self.currentInstructionIndex]
      if not instruction then break end
      local OPName, A, B, C = unpack(instruction)
      local instructionFunction = self[OPName]
      if not instructionFunction then error(("Unsupported instruction: %s"):format(OPName)) end
      instructionFunction(self, lines, A, B, C)
      self.currentInstructionIndex = self.currentInstructionIndex + 1 
    end

    return lines
  end;
  function InstructionRangeDecompilerObject.consumeInstruction(self)
    self.currentInstructionIndex = self.currentInstructionIndex + 1
    return self.instructions[self.currentInstructionIndex]
  end;
  function InstructionRangeDecompilerObject.skipInstructions(self, number)
    self.currentInstructionIndex = self.currentInstructionIndex + number
  end
  function InstructionRangeDecompilerObject.peekInstruction(self, number)
    return self.instructions[self.currentInstructionIndex + (number or 1)]
  end;
  function InstructionRangeDecompilerObject.processConstant(self, constant)
    if type(constant) == "string" then
      return "'" .. constant .. "'"
    end
    return tostring(constant)
  end;
  function InstructionRangeDecompilerObject.processRegisterOrConstant(self, integer)
    local isConstant = integer < 0
    if isConstant then
      return self:processConstant(self.constants[-integer])
    else
      return ("Register_%d"):format(integer)
    end
  end;
  function InstructionRangeDecompilerObject.formLineOfCode(self, line, indentation)
    local indentation = indentation or self.indentation
    return (rep("  ", indentation) .. line)
  end;

  function InstructionRangeDecompilerObject.LOADK(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local constant = self:processConstant(self.constants[-B])
    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, constant)))
  end;
  function InstructionRangeDecompilerObject.GETGLOBAL(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local constant = self.constants[-B]--self:processConstant(self.constants[-B])
    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s" --"Register_%d = getfenv()[%s]"
    insert(linesTb, self:formLineOfCode(formatString:format(A, constant)))
  end;
  function InstructionRangeDecompilerObject.MOVE(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = Register_%d"
    insert(linesTb, self:formLineOfCode(formatString:format(A, B)))
  end;
  
  function InstructionRangeDecompilerObject.ADD(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s + %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))))
  end;
  function InstructionRangeDecompilerObject.SUB(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s - %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))))
  end;
  function InstructionRangeDecompilerObject.MUL(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s * %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))))
  end;
  function InstructionRangeDecompilerObject.DIV(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s / %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))))
  end;
  function InstructionRangeDecompilerObject.POW(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = %s ^ %s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))))
  end;
  function InstructionRangeDecompilerObject.UNM(self, linesTb, A, B, C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = -%s"
    insert(linesTb, self:formLineOfCode(formatString:format(A, self:processRegisterOrConstant(B))))
  end;

  function InstructionRangeDecompilerObject.CALL(self, linesTb, A, B, C)
    local returnRegisters = {}
    for i = A, A + C - 2 do
      insert(returnRegisters, ("Register_%d"):format(i))
    end
    local arguments = {}
    for i = A + 1, A + B - 1 do
      insert(arguments, ("Register_%d"):format(i))
    end

    if #returnRegisters ~= 0 then
      insert(linesTb, self:formLineOfCode(("%s = Register_%d(%s)"):format(concat(returnRegisters, ", "), A, concat(arguments, ", ")) ))
    else
      insert(linesTb, self:formLineOfCode(("Register_%d(%s)"):format(A, concat(arguments, ", "))))
    end
  end
  function InstructionRangeDecompilerObject.GETTABLE(self, linesTb, A, B, C)
    local C = self:processRegisterOrConstant(C)
    local isRegisterDeclared = self.declaredRegisters[A]
    self.declaredRegisters[A] = true

    local formatString = (not isRegisterDeclared and "local " or "") .. "Register_%d = Register_%d[%s]"
    insert(linesTb, self:formLineOfCode(formatString:format(A, B, C)))
  end;
  function InstructionRangeDecompilerObject.CLOSURE(self, linesTb, A, B, C)
    insert(linesTb, self:formLineOfCode(("local function Register_%d()"):format(A)))
    for i, v in ipairs(GetLines(self.decompiledProtos[B + 1])) do
      insert(linesTb, self:formLineOfCode(v))
    end
    insert(linesTb, self:formLineOfCode("end"))
  end;
  function InstructionRangeDecompilerObject.VARARG(self, linesTb, A, B, C)
    local registers = {}
    for i = A, A+B-1 do
      insert(registers, ("Registers_%d"):format(i))
    end
    insert(linesTb, self:formLineOfCode(("%s = ..."):format(concat(registers, ", "))))
  end;
  function InstructionRangeDecompilerObject.TEST(self, linesTb, A, B, C)
    local nextInstruction = self:consumeInstruction()
    local nextOPName, jumpLength = unpack(nextInstruction or {})
    if not (nextOPName == "JMP") then
      error("Invalid TEST instruction")
    end

    local instructionOnJump = self:peekInstruction(jumpLength)
    local instructionOnJumpName, instructionOnJumpA = unpack(instructionOnJump)

    if instructionOnJumpName == "JMP" then  -- it's either "if ... else ... end" or "while ... do ... end" type
      local jumpLength2 = instructionOnJumpA
      if jumpLength2 >= 0 then -- it's "if ... else ... end" type
        
        local instructionBlock1 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength - 1, self.indentation + 1)
        self:skipInstructions(jumpLength)
        local instructionBlock2 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength2, self.indentation + 1)
        self:skipInstructions(jumpLength2)
      else
        -- The second block is condition
        -- it may be strange to start from the second block, but
        -- it's smarter, because we don't need to jump back later
        local instructionBlock2 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, (self.currentInstructionIndex + jumpLength) + (jumpLength2 + 1), self.currentInstructionIndex - 2, self.indentation + 1)
        -- The first block is a code block inside of "while" statement 
        local instructionBlock1 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength - 1, self.indentation + 1)
        self:skipInstructions(jumpLength)
        
        local condition = ("%s(Register_%d)"):format(B ~= 1 and "not " or "", A)
        insert(instructionBlock2, self:formLineOfCode(("if %s then break end"):format(condition), self.indentation + 1))
        insert(linesTb, self:formLineOfCode("while true do"))
        for _, line in ipairs(instructionBlock2) do
          insert(linesTb, line)
        end
        for _, line in ipairs(instructionBlock1) do
          insert(linesTb, line)
        end
        insert(linesTb, self:formLineOfCode("end"))
      end
    else -- it's "if ... end" type
      local instructionBlock = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength, self.indentation + 1)
      self:skipInstructions(jumpLength)
    end
  end;
  function InstructionRangeDecompilerObject.EQ(self, linesTb, A, B, C)
    -- if ((RK(B) == RK(C)) ~= A) then pc++ 
    local nextInstruction = self:consumeInstruction()
    local nextOPName, jumpLength = unpack(nextInstruction or {})
    if not (nextOPName == "JMP") then
      error("Invalid TEST instruction")
    end

    local instructionOnJump = self:peekInstruction(jumpLength)
    local instructionOnJumpName, instructionOnJumpA = unpack(instructionOnJump)

    if instructionOnJumpName == "JMP" then  -- it's either "if ... else ... end" or "while ... do ... end" type
      local jumpLength2 = instructionOnJumpA
      if jumpLength2 >= 0 then -- it's "if ... else ... end" type
        local instructionBlock1 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength - 1, self.indentation + 1)
        self:skipInstructions(jumpLength)
        local instructionBlock2 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength2, self.indentation + 1)
        self:skipInstructions(jumpLength2)
        Helpers.PrintTable(instructionBlock1)
        Helpers.PrintTable(instructionBlock2)
      else
        -- The second block is condition
        -- it may be strange to start from the second block, but
        -- it's smarter, because we don't need to jump back later
        local instructionBlock2 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, (self.currentInstructionIndex + jumpLength) + (jumpLength2 + 1), self.currentInstructionIndex - 2, self.indentation + 1)
        -- The first block is a code block inside of "while" statement 
        local instructionBlock1 = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength - 1, self.indentation + 1)
        self:skipInstructions(jumpLength)
        
        local condition = ("%s(%s == %s)"):format(A ~= 1 and "not " or "", self:processRegisterOrConstant(B), self:processRegisterOrConstant(C))
        insert(instructionBlock2, self:formLineOfCode(("if %s then break end"):format(condition), self.indentation + 1))
        insert(linesTb, self:formLineOfCode("while true do"))
        for _, line in ipairs(instructionBlock2) do
          insert(linesTb, line)
        end
        for _, line in ipairs(instructionBlock1) do
          insert(linesTb, line)
        end
        insert(linesTb, self:formLineOfCode("end"))
      end
    else -- it's "if ... end" type
      local instructionBlock = InstructionRangeDecompiler.new():decompile(self.instructions, self.constants, self.declaredRegisters, self.decompiledProtos, self.currentInstructionIndex + 1, self.currentInstructionIndex + jumpLength, self.indentation + 1)
      self:skipInstructions(jumpLength)
    end
  end

  function InstructionRangeDecompilerObject.JMP(self, linesTb, A, B, C)
    
  end

  function InstructionRangeDecompilerObject.RETURN(self, linesTb, A, B, C)
    local registers = {}
    for i = A, A + B - 2 do
      insert(registers, ("Register_%d"):format(i))
    end
    insert(linesTb, self:formLineOfCode(("return %s"):format(concat(registers, ", "))))
    
    -- Stop decompiling current instruction section
    self.shouldStop = true
  end

  return InstructionRangeDecompilerObject
end

return InstructionRangeDecompiler