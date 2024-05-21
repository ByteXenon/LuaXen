--[[
  Name: Debug.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module stores the Lua alternative functions to the Lua debug library.
--]]

local function getinfo(self, functionOrLevel, fieldName)
  if type(functionOrLevel) == "table" then
    local func = functionOrLevel
    return func
  end

  local level = functionOrLevel
  local information = self:getStackInformation(level + 1)
  return information
end

local function traceback(self)
  local tracebackString = ""
  for level, information in ipairs(self.closureStack) do
    tracebackString = tracebackString .. "  " .. tostring(level) .. ". " .. tostring(information.source) .. ":" .. tostring(information.currentline) .. "\n"
  end
  return tracebackString
end

--* Debug *--
local Debug = {
  getinfo = getinfo,
  traceback = traceback
}

return Debug