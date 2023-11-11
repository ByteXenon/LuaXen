--[[
  Name: InstructionGenerator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ExpressionEvaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionEvaluator")
local NodeToInstructionsConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/NodeToInstructionsConverter")
local ScopeState = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ScopeState")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* InstructionGenerator *--
local InstructionGenerator = {}
function InstructionGenerator:new(AST, luaState)
  local InstructionGeneratorInstance = {}
  InstructionGeneratorInstance.luaState = luaState or LuaState:new()
  InstructionGeneratorInstance.AST = AST
  InstructionGeneratorInstance.registers = {}
  for _, tb in ipairs({ExpressionEvaluator:new(), NodeToInstructionsConverter}) do
    for index, value in pairs(tb) do
      InstructionGeneratorInstance[index] = value
    end
  end

  function InstructionGeneratorInstance:getFutureAllocatedRegister()
    for i = 0, 255 do
      if not self.registers[i] then return i end
    end
    --return #self.registers + 1
  end
  function InstructionGeneratorInstance:allocateRegister()
    local registerIndex = self:getFutureAllocatedRegister() -- In case we change the allocation method
    self.registers[registerIndex] = true
    -- self.latestAllocatedRegister = registerIndex
    return registerIndex
  end;
  function InstructionGeneratorInstance:deallocateRegister(registerIndex)
    if not registerIndex then return end
    -- We don't deallocate constants
    if registerIndex < 0 then return end

    self.registers[registerIndex] = nil
  end;
  function InstructionGeneratorInstance:deallocateRegisters(registers)
    for _, register in ipairs(registers) do
      self.registers[register] = nil
    end
  end

  function InstructionGeneratorInstance:addConstant(newConstant)
    local constants = self.luaState.constants
    local constantIndex = find(constants, newConstant)
    if not constantIndex then
      insert(constants, newConstant)
      constantIndex = #constants
    end
    return -constantIndex
  end

  function InstructionGeneratorInstance:addASTNumber(number)
    return { TYPE = "Number", Value = number }
  end
  function InstructionGeneratorInstance:addASTString(str)
    return { TYPE = "String", Value = str }
  end
  function InstructionGeneratorInstance:addASTOperator(value, left, right, operand)
    return { TYPE = "Operator", Value = value, Left = left, Right = right, Operand = operand }
  end
  function InstructionGeneratorInstance:addASTFunctionCall(expression, arguments)
    return { TYPE = "FunctionCall", Expression = expression, Arguments = arguments}
  end
  function InstructionGeneratorInstance:addASTConstant(value)
    return { TYPE = "Constant", Value = value }
  end

  function InstructionGeneratorInstance:addInstruction(opName, a, b, c)
    insert(self.luaState.instructions, { opName, a, b, c })
    return #self.luaState.instructions
  end
  function InstructionGeneratorInstance:addInstructions(instructionTb)
    local instructions = self.luaState.instructions
    for _, instruction in ipairs(instructionTb) do
      insert(instructions, instruction)
    end
  end
  function InstructionGeneratorInstance:changeInstruction(instructionIndex, opName, a, b, c)
    local oldInstruction = self.luaState.instructions[instructionIndex]

    self.luaState.instructions[instructionIndex] = {
      (opName == false and oldInstruction[1]) or opName,
      (a == false and oldInstruction[2]) or a,
      (b == false and oldInstruction[3]) or b,
      (c == false and oldInstruction[4]) or c
    }
  end

  function InstructionGeneratorInstance:processNode(node)
    local type = node.TYPE
    if self["__CodeBlock_" .. type] then
      return self["__CodeBlock_" .. type](self, node)
    else
      return error("Unsupported node type: " .. type)
    end
  end;
  function InstructionGeneratorInstance:processCodeBlock(codeBlockNode)
    local oldScopeState = self.currentScopeState
    self.currentScopeState = ScopeState:new(self.luaState, self, self.currentScopeState)
    for _, node in ipairs(codeBlockNode) do
      self:processNode(node)
    end
    self.currentScopeState = oldScopeState

    return self.luaState
  end
  function InstructionGeneratorInstance:run()
    self:processCodeBlock(self.AST)
    self:addInstruction("RETURN", 0, 1)

    return self.luaState
  end

  return InstructionGeneratorInstance
end

return InstructionGenerator