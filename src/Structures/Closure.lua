--[[
  Name: Closure.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-30
  Description:
    This file defines the Closure structure used in the Lua interpreter.
    A Closure represents a function together with its upvalues.
    Closure structures are created during runtime when a function is invoked or when it is referenced as an upvalue.
    Each Closure contains a pointer to the function's Proto and a list of UpVal structures for its upvalues.
    Closures represent the dynamic execution of the code, allowing functions to access and manipulate their upvalues.
--]]

--* Closure *--
local Closure = {}
function Closure:new()
  local ClosureInstance = {}

  ClosureInstance.proto = nil
  ClosureInstance.upvalues = nil
  ClosureInstance.stack = nil
  ClosureInstance.base = nil

  return ClosureInstance
end

return Closure