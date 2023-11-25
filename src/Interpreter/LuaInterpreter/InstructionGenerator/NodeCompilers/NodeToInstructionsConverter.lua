--[[
  Name: NodeToInstructionsConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module stores the functions for
    converting AST statement nodes to instructions.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/NodeToInstructionsConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert
local unpack = (unpack or table.unpack)

--* NodeToInstructionsConverter *--
local NodeToInstructionsConverter = {}

-- FunctionCall: { Expression: {}, Arguments: {} }
function NodeToInstructionsConverter:FunctionCall(node)
  self:processExpressionNode(node)

  return -666
end

-- ReturnStatement: { Expressions: {} }
function NodeToInstructionsConverter:ReturnStatement(node)
  local expressions = node.Expressions
  local expressionRegisters = {}
  
  for index, expression in ipairs(expressions) do
    local expressionRegister = self:processExpressionNode(expression)
    -- If the expressions are not consecutive, move them to consecutive registers
    if expressionRegister ~= index then
      -- OP_MOVE [A, B]    R(A) := R(B)
      self:addInstruction("MOVE", index, expressionRegister)
    end
    insert(expressionRegisters, expressionRegister)
  end

  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  self:addInstruction("RETURN", expressionRegisters[1], (expressionRegisters[1] + #expressionRegisters) + 1)
  self:deallocateRegisters(expressionRegisters)
end

-- LocalVariable: { Expressions: {}, Variables: {} }
function NodeToInstructionsConverter:LocalVariable(node)
  local expressions = node.Expressions
  local variables = node.Variables

  local expressionRegisters = {}
  for index, expression in ipairs(expressions) do
    local expressionRegister = self:processExpressionNode(expression)
    insert(expressionRegisters, expressionRegister)
  end

  for index, expressionRegister in ipairs(expressionRegisters) do
    local expressionVariable = variables[index]
    if not expressionVariable then
      -- If the register of the expression cannot be used (in this case allocated to a variable).
      -- Then we just mark it as free.
      self:deallocateRegister(expressionRegister)
    else
      self:registerVariable(expressionVariable.Value, expressionRegister)
    end
  end
end

-- VariableAssignment: { Expressions: {}, Variables: {} }
function NodeToInstructionsConverter:VariableAssignment(node)
  local expressions = node.Expressions
  local variables = node.Variables
 
  local expressionRegisters = {}
  for index, expression in ipairs(expressions) do
    local expressionRegister = self:processExpressionNode(expression)
    insert(expressionRegisters, expressionRegister)
  end

  for index, variable in ipairs(variables) do
    local variableType = variable.TYPE

    -- "[<Identifier>]+ [=? <Expression>*]" type of assignment
    if variableType == "Identifier" then
      local variableName = variable.Value

      local variableExpressionRegister = expressionRegisters[index]
      local localVariableRegister = self.currentScope.locals[variableName]
      
      if not localVariableRegister then
        -- It's a global variable assignment
        -- OP_SETGLOBAL [A, Bx]    Gbl[Kst(Bx)] := R(A)
        self:addInstruction("SETGLOBAL", variableExpressionRegister, self:addConstant(variableName))
      else
        -- It's a local variable assignment
        -- OP_MOVE [A, B]    R(A) := R(B)
        self:addInstruction("MOVE", localVariableRegister, variableExpressionRegister)
      end
    -- "[<Identifier>[.<Identifier>]+] [=? <Expression>*]" type of assignment
    elseif variableType == "Index" then
      local index = variable.Index
      local expression = variable.Expression

      local expressionRegister = self:processExpressionNode(expression)
      local indexConstant = self:processExpressionNode(index, true)

      local expressionExpressionRegister = expressionRegisters[index]
      local expressionIndexConstant = expressionRegisters[indexConstant]

      -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
      self:addInstruction("SETTABLE", expressionExpressionRegister, expressionIndexConstant, expressionRegister)
    end
  end

  -- Deallocate all expression registers, they're not needed anymore
  self:deallocateRegisters(expressionRegisters)
end

-- DoStatement: { CodeBlock: {} }
function NodeToInstructionsConverter:DoStatement(node)
  local codeBlock = node.CodeBlock
  self:processCodeBlock(codeBlock)
end


local function processCondition(self, condition)
  -- Process the condition expression and get the register and instructions.
  local conditionRegister, conditionInstructions = self:processExpressionNode(condition, nil, true)

  -- Check the last instruction. If it's a comparison instruction, we don't need to add a "TEST" instruction.
  local lastConditionInstruction = conditionInstructions[#conditionInstructions]
  local lastConditionInstructionName = lastConditionInstruction[1]
  local comparisonInstructions = {["LE"] = true, ["LT"] = true, ["EQ"] = true}
  local shouldPlaceTest = not comparisonInstructions[lastConditionInstructionName]

  -- Deallocate the register used by the condition.
  self:deallocateRegister(conditionRegister)

  -- If necessary, add a "TEST" instruction to check the condition.
  if shouldPlaceTest then
    self:addInstruction("TEST", conditionRegister, 0)
  end

  -- Add a placeholder "JMP" instruction. The target of the jump will be filled in later.
  local conditionJump = self:addInstruction("JMP", 0)

  return conditionJump
end

local function processCodeBlock(self, codeBlock, isElse)
  local generatedInstructions = self:processCodeBlock(codeBlock, true)
  if not isElse then
    -- Little optimization, "else" statements don't need to jump to the end of the if statement.
    local endJumpInstruction = self:addInstruction("JMP", 0)
  end

  return generatedInstructions, endJumpInstruction
end

-- IfStatement: { Condition: {}, CodeBlock: {}, ElseIfs: {}, Else: {} }
function NodeToInstructionsConverter:IfStatement(node)
  local condition = node.Condition
  local codeBlock = node.CodeBlock
  local elseIfs = node.ElseIfs
  local elseStatement = node.Else

  local endJumpInstructions = {}

  local mainConditionJump = processCondition(self, condition)

  local codeBlockgeneratedInstructions, endJumpInstruction = processCodeBlock(self, codeBlock)
  insert(endJumpInstructions, endJumpInstruction)

  self:changeInstruction(mainConditionJump, "JMP", #codeBlockgeneratedInstructions + 1)

  for index, elseIfNode in ipairs(elseIfs) do
    local elseIfConditionJump = processCondition(self, elseIfNode.Condition)

    local elseIfCodeBlockgeneratedInstructions, endJumpInstruction = processCodeBlock(self, elseIfNode.CodeBlock)
    insert(endJumpInstructions, endJumpInstruction)

    self:changeInstruction(elseIfConditionJump, "JMP", #elseIfCodeBlockgeneratedInstructions + 1)
  end

  if elseStatement then
    local elseCodeBlockgeneratedInstructions, endJumpInstruction = processCodeBlock(self, elseStatement.CodeBlock, true)
  end

  for _, endJumpInstruction in ipairs(endJumpInstructions) do
    self:changeInstruction(endJumpInstruction, "JMP", #codeBlockgeneratedInstructions + 1)
  end
end

-- NumericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
function NodeToInstructionsConverter:NumericFor(node)
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local codeBlock = node.CodeBlock
  
  local iteratorVariable = iteratorVariables[1]

  local iteratorStart = self:processExpressionNode(expressions[1])
  local iteratorEnd = self:processExpressionNode(expressions[2])
  local iteratorStep
  if expressions[3] then
    iteratorStep = self:processExpressionNode(expressions[3])
  else
    iteratorStep = self:allocateRegister()
    self:addInstruction("LOADK", iteratorStep, self:findOrAddConstant(1))
  end

  -- OP_FORPREP [A, Bx]    R(A)-=R(A+2); pc+=Bx
  local forLoopInstruction = self:addInstruction("FORPREP", iteratorStart, 0)

  self:pushScope()
  self:registerVariable(iteratorVariable, iteratorStart)
  local codeBlockgeneratedInstructions = self:processCodeBlock(codeBlock, true)
  self:popScope()

  self:changeInstruction(forLoopInstruction, "FORPREP", iteratorStart, #codeBlockgeneratedInstructions)

  -- OP_FORLOOP [A, Bx]    R(A)+=R(A+2);
  --                       if R(A) <?= R(A+1) then { pc+=Bx; R(A+3)=R(A) }
  self:addInstruction("FORLOOP", iteratorStart, -(#codeBlockgeneratedInstructions + 1))
end

-- GenericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
function NodeToInstructionsConverter:GenericFor(node)
  -- JMP
  --  <codeBlock>
  -- OP_TFORLOOP

  -- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
  --                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++

  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local codeBlock = node.CodeBlock

  local expressionRegister = self:processExpressionNode(expressions[1])
  local jumpInstruction = self:addInstruction("JMP", 0)

  self:pushScope()
  for index, iteratorVariable in ipairs(iteratorVariables) do
    local varRegister = self:allocateRegister()
    self:registerVariable(iteratorVariable, varRegister)
  end

  local codeBlockgeneratedInstructions = self:processCodeBlock(codeBlock, true)
  self:popScope()

  self:changeInstruction(jumpInstruction, "JMP", #codeBlockgeneratedInstructions - 1)

  self:addInstruction("TFORLOOP", self:allocateRegister(), #iteratorVariables - 1)
end

return NodeToInstructionsConverter