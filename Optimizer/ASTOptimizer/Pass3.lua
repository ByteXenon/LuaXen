--[[
  Name: Pass3.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--! TODO
-- Pass3: Advanced optimizations

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/Pass3")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Pass3 *--
local Pass3 = {}
function Pass3:new(astHierarchy)
  local Pass3Instance = {}
  Pass3Instance.ast = astHierarchy

  function Pass3Instance:run()
    return self.ast
  end
  
  return Pass3Instance
end

return Pass3