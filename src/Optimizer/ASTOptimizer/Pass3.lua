--[[
  Name: Pass3.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

-- Pass3: Advanced optimizations

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/Pass3")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Pass3 *--
local Pass3 = {}
function Pass3:new(astHierarchy)
  local Pass3Instance = {}
  Pass3Instance.ast = astHierarchy

  function Pass3Instance:eliminateDeadIfStatements()
    local ifStatements = self.ast:getDescendantsWithType("IfStatement")
    for index, ifStatement in ipairs(ifStatements) do
      -- `elseif` and `else` statements are not supported for now.
      local isValidToOptimize = (#ifStatement.ElseIfs == 0 and not ifStatement.Else)
      if isValidToOptimize then
        local conditionValue = ifStatement.Condition.Value
        -- It was probably optimized by Pass1
        if conditionValue.TYPE == "Constant" then
          local constantValue = conditionValue.Value
          if constantValue then
            ifStatement:remove()
            ifStatement.Parent:addNodesToStart(ifStatement.CodeBlock)
          else
            ifStatement:remove()
          end
        end
      end
    end
  end

  function Pass3Instance:run()
    self:eliminateDeadIfStatements()
    return self.ast
  end

  return Pass3Instance
end

return Pass3