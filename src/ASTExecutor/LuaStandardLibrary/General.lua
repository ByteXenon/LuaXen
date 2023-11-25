--[[
  Name: General.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module stores the Lua alternative functions to the Lua standard library.
    You may ask why I did this. The thing is, Lua C functions use Lua C API to get arguments,
    and the Lua C API doesn't go well with my "nil" values passed from the ASTExecutor to functions.
    So we have to reimplement the functions in Lua, and then call them from the ASTExecutor.
    It's not really required, it's more for specific cases where emulated scripts detect my ASTExecutor. 
--]]

--* General *--
local General = {}

function General:select(luaState)
  local args = {...}
  if num < 0 then
    num = #args + num + 1
  end

  return args[num]
end

function General:print(luaState)
  local args = {...}
  local string = ""
  for i = 1, #args do
    string = string .. tostring(args[i])
  end
  print(string)
end

function General:tostring(luaState)
  return tostring(value)
end

return General