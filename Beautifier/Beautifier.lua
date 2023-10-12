--[[
  Name: Beautifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Beautifier/Beautifier")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Printer = ModuleManager:loadModule("Printer/Printer")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* Beautifier *--
local Beautifier = {}
function Beautifier:new(astHierarchy)
  local BeautifierInstance = {}
  BeautifierInstance.ast = astHierarchy
  BeautifierInstance.indentationLevel = 0;

  function BeautifierInstance:processCodeBlock(nodeList)
    local nodeStrings = {}
    for _, node in ipairs(nodeList) do
      insert(nodeStrings, node:printTokens())
    end
    return concat(nodeStrings, "\n")
  end

  function BeautifierInstance:run()
    return self:processCodeBlock(self.ast)
  end

  return BeautifierInstance
end

return Beautifier