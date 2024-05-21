--[[
  Name: InstructionParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* InstructionParser *--
local InstructionParser = {}
function InstructionParser:new(state)
  local InstructionParserInstance = {}
  local instructions = state.instructions or state

  InstructionParserInstance.instructions = instructions
  InstructionParserInstance.currentInstructionIndex = 1
  InstructionParserInstance.currentInstruction = instructions[1]

  function InstructionParserInstance:peek(n)
    return self.instructions[self.currentInstructionIndex + (n or 1)]
  end
  function InstructionParserInstance:consume(n)
    self.currentInstructionIndex = self.currentInstructionIndex + (n or 1)
    self.currentInstruction = self.instructions[self.currentInstructionIndex]
    return self.currentInstruction
  end

  function InstructionParserInstance:processCurrentInstruction(instruction)

  end
  function InstructionParserInstance:run()
    local ast = {}
    while self.currentInstruction do
      insert(ast, self:processCurrentInstruction())
    end
    return ast
  end

  return InstructionParserInstance
end

return InstructionParser