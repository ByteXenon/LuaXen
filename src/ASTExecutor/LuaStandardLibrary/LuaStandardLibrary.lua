--[[
  Name: LuaStandardLibrary.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module stores the Lua alternative functions to the Lua standard library.
    You may ask why I did this. The thing is, Lua C functions use Lua C API to get arguments,
    and the Lua C API doesn't go well with my "nil" values passed from the ASTExecutor to functions.
    So we have to reimplement the functions in Lua, and then call them from the ASTExecutor.
    It's not really required, it's more for specific cases where emulated scripts detect my ASTExecutor.
--]]

--* LuaStandardLibrary *--
local LuaStandardLibrary = {}
function LuaStandardLibrary:new(ASTExecutorInstance)
  local LuaStandardLibraryInstance = {}
  LuaStandardLibraryInstance.ASTExecutorInstance = ASTExecutorInstance
  LuaStandardLibraryInstance.loadedScripts = {}

  return LuaStandardLibraryInstance
end

return LuaStandardLibrary