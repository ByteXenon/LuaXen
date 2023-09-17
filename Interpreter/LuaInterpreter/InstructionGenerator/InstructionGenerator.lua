--[[
  Name: InstructionGenerator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ExpressionsEvaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionsEvaluator")
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
  InstructionGeneratorInstance.expressionsEvaluator = ExpressionsEvaluator:new(InstructionGeneratorInstance) 

  function InstructionGeneratorInstance:getFutureAllocatedRegister()
    for i = 1, 255 do
      if not self.registers[i] then return i end
    end
    --return #self.registers + 1
  end
  function InstructionGeneratorInstance:allocateRegister()
    local registerIndex = self:getFutureAllocatedRegister() -- In case we change the allocation method
    --print(registerIndex, debug.traceback())
    self.registers[registerIndex] = true
    return registerIndex
  end;
  function InstructionGeneratorInstance:deallocateRegister(registerIndex)
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
  function InstructionGeneratorInstance:changeInstruction(instructionIndex, opName, a, b, c)
    local oldInstruction = self.luaState.instructions[instructionIndex]
    local opName = (opName == false and oldInstruction[1]) or opName
    local a = (a == false and oldInstruction[2]) or a
    local b = (b == false and oldInstruction[3]) or b
    local c = (c == false and oldInstruction[4]) or c

    self.luaState.instructions[instructionIndex] = { opName, a, b, c }
  end

  function InstructionGeneratorInstance:processNode(node)
    local type = node.TYPE
    if type == "LocalVariable" then
      local variables = node.Variables
      local expressions = node.Expressions

      for index, expression in ipairs(expressions) do
        local expressionReturnRegister = self.expressionsEvaluator:evaluateExpression(expression)
        local variableName = variables[index]
        if not variableName then
          self:deallocateRegister(expressionReturnRegister)
        else
          local nextAllocatedRegister = self:getFutureAllocatedRegister()
          local localRegister = expressionReturnRegister
          if nextAllocatedRegister - 1 == expressionReturnRegister then
          else
            localRegister = self:allocateRegister()
            self:addInstruction("MOVE", localRegister, expressionReturnRegister)
          end

          self.currentScopeState:setLocal(localRegister, variableName)
        end

        --[[if variableRegisters[index] then
          self:addInstruction("MOVE", variableRegisters[index], expressionReturnRegister)
        end]]
      end
    elseif type == "FunctionCall" then
      self.expressionsEvaluator:evaluateExpression(node)
    end
  end;
  function InstructionGeneratorInstance:processCodeBlock(codeBlockNode)
    local oldScopeState = self.currentScopeState
    self.currentScopeState = ScopeState:new(self.luaState, self, self.currentScopeState)
    for _, node in ipairs(codeBlockNode) do
      self:processNode(node)
    end
    self.currentScopeState = oldScopeState
  end
  function InstructionGeneratorInstance:run()
    self:processCodeBlock(self.AST)
    self:addInstruction("RETURN", 0, 1)
    
    return self.luaState
  end

  return InstructionGeneratorInstance
end

return InstructionGenerator