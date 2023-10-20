--[[
  Name: ASTOptimizer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/ASTOptimizer/ASTOptimizer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Pass1 = ModuleManager:loadModule("Optimizer/ASTOptimizer/Pass1")
local Pass2 = ModuleManager:loadModule("Optimizer/ASTOptimizer/Pass2")
local Pass3 = ModuleManager:loadModule("Optimizer/ASTOptimizer/Pass3")

--* ASTOptimizer *--
local ASTOptimizer = {}
function ASTOptimizer:new(astHierarchy)
  local ASTOptimizerInstance = {}
  ASTOptimizerInstance.ast = astHierarchy

  function ASTOptimizerInstance:run()
    -- I like this code
    return Pass3:new(Pass2:new(Pass1:new(self.ast):run()):run()):run()
  end

  return ASTOptimizerInstance
end

return ASTOptimizer