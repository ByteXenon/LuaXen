--[[
  Name: Optimizer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Optimizations = {}

--* OptimizerMethods *--
local OptimizerMethods = {}

function OptimizerMethods:optimize()

end

--* Optimizer *--
local Optimizer = {}
function Optimizer:new(ast)
  local OptimizerInstance = {}
  OptimizerInstance.ast = ast

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if OptimizerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and OptimizerInstance: " .. index)
      end
      OptimizerInstance[index] = value
    end
  end

  -- Main
  inheritModule("OptimizerMethods", OptimizerMethods)

  return OptimizerInstance
end


return Optimizer