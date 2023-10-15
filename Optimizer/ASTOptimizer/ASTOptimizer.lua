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

--* ASTOptimizer *--
local ASTOptimizer = {}
function ASTOptimizer:new(astHierarchy)
  local ASTOptimizerInstance = {}
  ASTOptimizerInstance.ast = astHierarchy

  function ASTOptimizerInstance:run()
    self.ast = Pass1:new(self.ast):run()
    self.ast = Pass2:new(self.ast):run()
    return self.ast
  end

  return ASTOptimizerInstance
end

return ASTOptimizer