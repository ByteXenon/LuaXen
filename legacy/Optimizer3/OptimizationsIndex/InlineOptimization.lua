--[[
  Name: InlineOptimization.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-03
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local ASTWalker = require("ASTWalker/ASTWalker")

--* InlineOptimization *--
local InlineOptimization = {}
function InlineOptimization:inline()
  ASTWalker:traverseNode(self.ast, function(node)
    return node.TYPE == "LocalFunction"
  end, function(node)
    local canInline = true
  end)
end

return InlineOptimization