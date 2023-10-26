--[[
  Name: NodeToInstructionsConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/NodeToInstructionsConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ExpressionEvaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ExpressionEvaluator")
local ScopeState = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/ScopeState")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* NodeToInstructionsConverter *--
local NodeToInstructionsConverter = {}
function NodeToInstructionsConverter:__CodeBlock_LocalFunction(node)
  local InstructionGenerator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")

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
end
function NodeToInstructionsConverter:__CodeBlock_LocalVariable(node)
  local variables = node.Variables
  local expressions = node.Expressions

  for index, expression in ipairs(expressions) do
    local expressionReturnRegister = self:evaluateExpression(self.luaState.instructions, expression.Value)
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
end
function NodeToInstructionsConverter:__CodeBlock_VariableAssignment(node)
  local variables = node.Variables
  local expressions = node.Expressions

  for index, expression in ipairs(expressions) do
    local expressionReturnRegister = self:evaluateExpression(self.luaState.instructions, expression.Value)
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
end
function NodeToInstructionsConverter:__CodeBlock_DoBlock(node)
  self:processCodeBlock(node.CodeBlock)
end
function NodeToInstructionsConverter:__CodeBlock_FunctionCall(node)
  local returnRegister = self:evaluateExpression(self.luaState.instructions, node)
  self:deallocateRegister(returnRegister)
end
function NodeToInstructionsConverter:__CodeBlock_IfStatement(node)
  local conditionReturnRegister, conditionInstructions = self:evaluateExpression(self.luaState.instructions, node.Condition.Value)
  local conditionValue = node.Condition.Value.Value
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
  if node.ElseIfs and node.ElseIfs[1] then
    self:changeInstruction(jmpInstruction, "JMP", newInstructionNumber - oldInstructionNumber + (node.Else and 1 or 0) )
    for index, elseIfStatement in ipairs(node.ElseIfs) do
      local conditionReturnRegister, conditionInstructions = self:evaluateExpression(self.luaState.instructions, elseIfStatement.Condition)
      local conditionValue = elseIfStatement.Condition.Value.Value
      if conditionValue == ">" or conditionValue == "<" or conditionValue == ">=" or conditionValue == "<=" then
      else
        self:addInstruction("TEST", conditionReturnRegister, 0)
      end
      local jmpInstruction = self:addInstruction("JMP", 0)
      local oldInstructionNumber = #self.luaState.instructions
      local codeBlockInstructions = self:processCodeBlock(elseIfStatement.CodeBlock)
      local newInstructionNumber = #self.luaState.instructions
    end
  end

  if node.Else then
    local elseJMPInstrIndx = self:addInstruction("JMP", 0)
    local oldInstructionNumber = #self.luaState.instructions
    self:processCodeBlock(node.Else.CodeBlock)
    local newInstructionNumber = #self.luaState.instructions
    self:changeInstruction(elseJMPInstrIndx, "JMP", newInstructionNumber - oldInstructionNumber)
  end
end
function NodeToInstructionsConverter:__CodeBlock_ReturnStatement(node)
  local startRegister;
  local returnRegisters = {}
  for index, node in ipairs(node.Expressions) do
    local returnRegister = self:evaluateExpression(self.luaState.instructions, node.Value)
    startRegister = startRegister or returnRegister
    insert(returnRegisters,returnRegister)
  end

  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  self:addInstruction("RETURN", startRegister, startRegister + #returnRegisters + 1)
end

return NodeToInstructionsConverter