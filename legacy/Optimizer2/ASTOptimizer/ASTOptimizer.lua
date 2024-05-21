--[[
  Name: ASTOptimizer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Pass1 = require("Optimizer/ASTOptimizer/Pass1")
local Pass2 = require("Optimizer/ASTOptimizer/Pass2")
local Pass3 = require("Optimizer/ASTOptimizer/Pass3")

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