--[[
  Name: DebugLibrary.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module is responsible for providing userspace global functions which would be useful for debugging.
--]]

--* Export library functions *--
local insert = table.insert
local concat = table.concat

--* DebugLibrary *--
local DebugLibrary = {
  Globals = {}
}

function DebugLibrary.Globals:getSelf()
  return self
end
function DebugLibrary.Globals:printFlags()
  local flags = {}
  for flagName, flagValue in pairs(self.globalFlags) do
    insert(flags, flagName .. " = " .. tostring(flagValue))
  end
  print(concat(flags, "\n"))
end

function DebugLibrary:setDebuggingGlobals(state)
  for globalName, globalValue in pairs(self.Globals) do
    state.env[globalName] = function(...)
      return globalValue(self, ...)
    end
  end
end

return DebugLibrary