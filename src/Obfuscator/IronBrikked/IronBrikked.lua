--[[
  Name: IronBrikked.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-08
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local ASTWalker = require("ASTWalker/ASTWalker")

local insert = table.insert

--* IronBrikkedMethods *--
local IronBrikkedMethods = {}

--* IronBrikked *--
local IronBrikked = {}
function IronBrikked:new(ast)
  local IronBrikkedInstance = {}
  IronBrikkedInstance.ast = ast

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if IronBrikkedInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and IronBrikkedInstance: " .. index)
      end
      IronBrikkedInstance[index] = value
    end
  end

  -- Main
  inheritModule("IronBrikkedMethods", IronBrikkedMethods)

  return IronBrikkedInstance
end

return IronBrikked