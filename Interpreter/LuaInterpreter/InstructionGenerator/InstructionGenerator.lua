--[[
  Name: InstructionGenerator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ExpressionEvaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionEvaluator")
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
  -- InstructionGeneratorInstance.latestAllocatedRegister;
  for i,v in pairs(ExpressionEvaluator:new()) do
    InstructionGeneratorInstance[i] = v
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
    if type == "LocalFunction" then
      local name = node.Name
      local parameters = node.Parameters
      local codeBlock = node.CodeBlock
      
      local protoLuaState = InstructionGenerator:new(node.CodeBlock):processCodeBlock(node.CodeBlock)
      insert(protoLuaState.instructions, {"RETURN", 0, 1})
      protoLuaState.parameters = parameters
      
      local functionRegister = self.currentScopeState:addLocal(name)
      insert(self.luaState.protos, protoLuaState)

      -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
      self:addInstruction("CLOSURE", functionRegister, #self.luaState.protos)
    elseif type == "LocalVariable" then
      local variables = node.Variables
      local expressions = node.Expressions

      for index, expression in ipairs(expressions) do
        local expressionReturnRegister = self:evaluateExpression(self.luaState.instructions, expression)
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

          self.currentScopeState:setLocal(localRegister, variableName.Value)
        end
      end
    elseif type == "VariableAssignment" then
      local variables = node.Variables
      local expressions = node.Expressions
      for index, expression in ipairs(expressions) do
        local expressionReturnRegister = self:evaluateExpression(self.luaState.instructions, expression)
        local variableName = variables[index].Value
        local localVariable = self.currentScopeState.locals[variableName]
        
        self:deallocateRegister(expressionReturnRegister)
        if not variableName then
        elseif not localVariable then
          self:addInstruction("SETGLOBAL", self:addConstant(variableName), expressionReturnRegister)
        else -- This is a known local variable
          self:addInstruction("MOVE", localVariable, expressionReturnRegister)
        end
      end
    elseif type == "DoBlock" then
      self:processCodeBlock(node.CodeBlock) 
    elseif type == "FunctionCall" then
      local returnRegister = self:evaluateExpression(self.luaState.instructions, node)
      self:deallocateRegister(returnRegister)
    elseif type == "IfStatement" then
      local conditionReturnRegister, conditionInstructions = self:evaluateExpression(self.luaState.instructions, node.Condition)
      local conditionValue = node.Condition.Value
      if conditionValue == ">" or conditionValue == "<" or conditionValue == ">=" or conditionValue == "<=" then
        -- Don't touch it, it already has a check
      else
        -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
        self:addInstruction("TEST", conditionReturnRegister, 0)
      end
      local jmpInstruction = self:addInstruction("JMP", 0)
      local oldInstructionNumber = #self.luaState.instructions
      local codeBlockInstructions = self:processCodeBlock(node.CodeBlock)
      local newInstructionNumber = #self.luaState.instructions
      self:changeInstruction(jmpInstruction, "JMP", newInstructionNumber - oldInstructionNumber )
    elseif type == "ReturnStatement" then
      local startRegister;
      local returnRegisters = {}
      for index, node in ipairs(node.Expressions) do
        local returnRegister = self:evaluateExpression(self.luaState.instructions, node)
        startRegister = startRegister or returnRegister 
        insert(returnRegisters,returnRegister) 
      end

      -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
      self:addInstruction("RETURN", startRegister, startRegister + #returnRegisters + 1)
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