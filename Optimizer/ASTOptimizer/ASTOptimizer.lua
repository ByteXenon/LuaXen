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
    local pass1AST = Pass1:new(self.ast):run()
    local pass2AST = Pass2:new(pass1AST):run()
    local pass3AST = pass3:new(pass2AST):run()

    return pass3AST
  end

  return ASTOptimizerInstance
end

return ASTOptimizer