--[[
  Name: Default.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Export library functions *--
local insert = table.insert

--* Default *--
local Default = {}
function Default:getChildren()
  local children = {}

  local getChildrenFromList;
  local function getChildrenFromList(list)
    if type(list) ~= "table" then return end
    if list.TYPE then return end
    for index, value in ipairs(list) do
      if value.TYPE then
        insert(children, value)
      end
    end
  end

  getChildrenFromList(self.CodeBlock)
  getChildrenFromList(self.Expressions)
  getChildrenFromList(self.Variables)
  return children
end
function Default:getDescendants()
  local descendants = {}
  local processChild;
  local function processChild(child)
    insert(descendants, child)
    for index, node in ipairs(child:getChildren()) do
      processChild(node)
    end
  end
  for index, node in ipairs(self:getChildren()) do
    processChild(node)
  end

  return descendants 
end

return Default