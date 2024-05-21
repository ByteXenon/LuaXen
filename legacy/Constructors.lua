--[[
  Name: Constructors.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-28
  Description:
--]]
--[==[

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Import library functions *--
local insert = table.insert
local find = (table.find or Helpers.tableFind)

--* Constructors *--
local Constructors = {}

--[[
  | if <Condition> then     | condition:
  | .                       |  Instructions(Expression(<Condition>))
  | .                       |  TEST R(<Condition>), 0 // Jumps to the codeblock, in some cases is not used.
  | .                       |  JMP #Instructions(code-block) // Jump to the end or to the next condition.
  | .  <CodeBlock>          | code-block:
  | .                       |  Instructions(CodeBlock(<CodeBlock>))
  | .                       |  JMP end // Jump to the very end of the entire if-statement.
  | elseif <Condition> then | elseif-condition: // Optional, can be repeated.
  | .                       |  Instructions(Expression(<ElseIf.Condition>))
  | .                       |  TEST R(<ElseIf.Condition>), 0
  | .                       |  JMP #Instructions(elseif-block) // Jump to the next elseif-condition, to the else-block, or to the end.
  | .  <CodeBlock>          | elseif-block:
  | .                       |  Instructions(CodeBlock(<ElseIf.CodeBlock>))
  | .                       |  JMP end
  | else                    | else-block: // Optional.
  | .  <CodeBlock>          |  Instructions(CodeBlock(<Else.CodeBlock>))
--]]
function Constructors:ifStatements(condition, codeBlock, elseIfStatements, elseBlock)
  local ifConditionCodeBlockStatements = {
    { Condition = condition, CodeBlock = codeBlock }
  }
  for index, elseIfStatement in ipairs(elseIfStatements) do
    insert(ifConditionCodeBlockStatements, elseIfStatement)
  end

  local jumpsToTheEndInstructionIndices = {}
  for index, ifConditionCodeBlockStatement in ipairs(ifConditionCodeBlockStatements) do
    local condition = ifConditionCodeBlockStatement.Condition
    local codeBlock = ifConditionCodeBlockStatement.CodeBlock

    local conditionJumpInstructionIndex = self.constructors.codeBlockConditionJump(self, condition, codeBlock)
    if index ~= #ifConditionCodeBlockStatements or elseBlock then
      local jumpAParam = self.luaState.instructions[conditionJumpInstructionIndex][2]
      -- Make it skip the next jump instruction too.
      self:changeInstruction(conditionJumpInstructionIndex, "JMP", jumpAParam + 1)

      -- Add a placeholder jump to the end of the if-statement, later it will be replaced with the correct jump.
      insert(jumpsToTheEndInstructionIndices, self:addInstruction("JMP", 1))
    end
  end

  -- Else
  if elseBlock then
    local elseBlockInstructions = self:processCodeBlock(elseBlock.CodeBlock, true)
  end

  for index, jumpToTheEndInstructionIndex in ipairs(jumpsToTheEndInstructionIndices) do
    self:changeInstruction(jumpToTheEndInstructionIndex, "JMP", #self.luaState.instructions - jumpToTheEndInstructionIndex)
  end
end

return Constructors
--]==]