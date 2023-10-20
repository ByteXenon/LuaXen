--[[
  Name: Pass2.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

-- Pass2: General optimizations

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/Pass2")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Pass2 *--
local Pass2 = {}
function Pass2:new(astHierarchy)
  local Pass2Instance = {}
  Pass2Instance.ast = astHierarchy

  function Pass2Instance:isFunctionUsed(functionName, scope)
    -- It's a simple check, but it works for now.
    local identifiers = scope:getDescendantsWithType("Identifier")
    for index, identifier in ipairs(identifiers) do
      if identifier.Value == functionName then
        return true
      end
    end
    return false
  end
  function Pass2Instance:removeDeadCode()
    local localFunctions = self.ast:getDescendantsWithType("LocalFunction")
    for index, localFunction in ipairs(localFunctions) do
      local functionIsUsed = self:isFunctionUsed(localFunction.Name, localFunction.Parent)
      if not functionIsUsed then
        localFunction:remove()
      end
    end
  end
  function Pass2Instance:run()
    self:removeDeadCode()
    return self.ast
  end
  
  return Pass2Instance
end

return Pass2