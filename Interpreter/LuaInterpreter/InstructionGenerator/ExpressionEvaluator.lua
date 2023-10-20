--[[
  Name: ExpressionEvaluator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionEvaluator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ScopeState = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ScopeState")
local ExpressionToInstructionsConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/ExpressionToInstructionsConverter")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* ExpressionEvaluator *--
local ExpressionEvaluator = {}
function ExpressionEvaluator:new()
  local ExpressionEvaluatorInstance = {}
  for index, value in pairs(ExpressionToInstructionsConverter) do
    ExpressionEvaluatorInstance[index] = value
  end

  local function addInstruction(instructions, opName, a, b, c)
    insert(instructions, { opName, a, b, c })
    return #instructions 
  end
  local function changeInstruction(instructions, instructionIndex, opName, a, b, c)
    local oldInstruction = instructions[instructionIndex]

    instructions[instructionIndex] = {
      (opName == false and oldInstruction[1]) or opName,
      (a == false and oldInstruction[2]) or a,
      (b == false and oldInstruction[3]) or b,
      (c == false and oldInstruction[4]) or c 
    }
  end

  function ExpressionEvaluatorInstance:evaluateExpressionNode(instructions, expression, canReturnConstantIndex, isStatementContext)
    local type = expression.TYPE
    if self[type] then
      return self[type](self, expression)
    else
      return error("Unsupported node type: " .. type)
    end
  end

  function ExpressionEvaluatorInstance:evaluateExpression(instructions, expression, canReturnConstantIndex, noInsert)
    local generatedInstructions = {};
    local returnRegister = self:evaluateExpressionNode(generatedInstructions, expression, canReturnConstantIndex)

    if not noInsert then
      for _, instruction in pairs(generatedInstructions) do
        insert(instructions, instruction)
      end
    end
    return returnRegister, generatedInstructions
  end

  return ExpressionEvaluatorInstance
end

return ExpressionEvaluator