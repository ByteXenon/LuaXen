--[[
  Name: Optimizer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Optimizer/Optimizer")
local ASTOptimizer = ModuleManager:loadModule("Optimizer/ASTOptimizer/ASTOptimizer")

--* Optimizer *--
local Optimizer = {}
function Optimizer:optimizeAST(ast)
  local newASTOptimizerInstance = ASTOptimizer:new(ast)
  return newASTOptimizerInstance:run()
end

return Optimizer