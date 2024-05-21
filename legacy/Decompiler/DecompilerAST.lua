--[[
  Name: DecompilerAST.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local LuaState = require("LuaState/LuaState")

--* Imports *--
local Class = Helpers.NewClass
local StringToTable = Helpers.StringToTable
local GetTableElementsFromTo = Helpers.GetTableElementsFromTo
local GetLines = Helpers.GetLines
local find = Helpers.FindTable
local insert = table.insert
local concat = table.concat

-- * DecompilerAST * --
local DecompilerAST = {}
function DecompilerAST:new(instructions)
  local DecompilerASTInstance = {}

  DecompilerASTInstance.instructions = instructions
  DecompilerASTInstance.instructionIndex = 1
  DecompilerASTInstance.currentInstruction = instructions[DecompilerASTInstance.instructionIndex]
  DecompilerASTInstance.instructionAST = {}
  DecompilerASTInstance.replacedFunctions = {}

  function DecompilerASTInstance:replaceVisitorFunctions(newFunctions)
    self.replacedFunctions = newFunctions
    for i, v in pairs(newFunctions) do
      self[i] = v
    end
  end

  function DecompilerASTInstance:peek(n)
    return self.instructions[self.instructionIndex + (n or 1)]
  end;
  function DecompilerASTInstance:consume(n)
    self.instructionIndex = self.instructionIndex + (n or 1)
    self.currentInstruction = self.instructions[self.instructionIndex]
    return self.currentInstruction
  end;

  function DecompilerASTInstance:default_visit(opname, A, B, C)
    return {
      OPName = opname,
      A = A,
      B = B,
      C = C,
      TYPE = "INSTRUCTION"
    }
  end
  function DecompilerASTInstance:TEST(A, B, C)
    -- there's always "JMP" after "TEST", it's a "slave" instruction
    local nextInstruction = self:consume()
    local nextOPName, jumpLength = unpack(nextInstruction or {})
    if not (nextOPName == "JMP") then
      -- well, it's not a natural input then,
      -- so we just throw an error
      error("Invalid TEST instruction")
    end

    --local instructionOnJump = self:consume(jumpLength)
    local instructionOnJump = self:peek(jumpLength)
    if instructionOnJump[1] == "JMP" then  -- it's either "if ... else ... end" or "while ... do ... end" type
      local jumpLength2 = instructionOnJump[2]
      if jumpLength2 >= 0 then -- it's "if ... else ... end" type
        local instructionBlock1 = self:proccessInstructionRange(self.instructionIndex + 1, self.instructionIndex + jumpLength)  
        self:consume(jumpLength)
        local instructionBlock2 = self:proccessInstructionRange(self.instructionIndex + 1, self.instructionIndex + jumpLength2)
        self:consume(jumpLength2)
        return {
          TYPE = "IF",
          CodeBlock = instructionBlock1,
          Else = instructionBlock2,
          Instruction = {A, B, C}
        }
      else -- "while ... do ... end"
        local instructionBlock1 = self:proccessInstructionRange(self.instructionIndex + jumpLength + jumpLength2 + 1, self.instructionIndex - 2)
        local whileEnd = self.instructionIndex
        local instructionBlock2 = self:proccessInstructionRange(self.instructionIndex + 1, self.instructionIndex + jumpLength - 1,
          {
            JMP = function(self, A, B, C)
              print(A)
              print(whileEnd + self.instructionIndex + A)
              return {}
            end
          }
        )
        self:consume(jumpLength)
        return {
          TYPE = "WHILE",
          Statement = instructionBlock1,
          CodeBlock = instructionBlock2,
          Instruction = {A, B, C}
        }
      end
    else -- if ... then end
      local instructionBlock1 = self:proccessInstructionRange(self.instructionIndex + 1, self.instructionIndex + jumpLength)
      self:consume(jumpLength)
      
      return {
        TYPE = "IF",
        CodeBlock = instructionBlock1,
        Instruction = {A, B, C}
      }
    end

    --Helpers.PrintTable(instructionBlock1)
    return {}
  end

  function DecompilerASTInstance:processInstruction(instruction)
    local OPName, A, B, C = unpack(instruction)
    local instructionVisitorFunction = self[OPName]
    if not instructionVisitorFunction then
      return self:default_visit(OPName, A, B, C)
    end
    return instructionVisitorFunction(self, A, B, C)
  end

  function DecompilerASTInstance:proccessInstructionRange(min, max, replacedVisitorFunctions)
    local instructions = GetTableElementsFromTo(self.instructions, min, max)
    local replacedVisitorFunctions = replacedVisitorFunctions or {}
    for i,v in pairs(self.replacedFunctions) do
      replacedVisitorFunctions[i] = v
    end
    local newInstance = DecompilerAST:new(instructions)
    newInstance:replaceVisitorFunctions(replacedVisitorFunctions)
    return newInstance:run()
  end

  function DecompilerASTInstance:run()
    local instructionAST = self.instructionAST
    while self.currentInstruction do
      insert(instructionAST, self:processInstruction(self.currentInstruction))
      self:consume()
    end

    return instructionAST
  end;

  return DecompilerASTInstance
end

return DecompilerAST