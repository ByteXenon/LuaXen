--[[
  Name: LuaState.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
  Description:
    This file defines the LuaState structure used in the Lua interpreter.
    A LuaState represents the state of a Lua interpreter, which includes all the information
    that the Lua interpreter needs to execute Lua code, such as the stack of call frames,
    the global environment, and other interpreter-wide state.
    Each LuaState is independent from each other, allowing for multiple, isolated Lua environments
    within the same program. This structure is crucial for the execution of Lua scripts,
    providing the context in which scripts run and manage their data.
--]]

local globalEnvironment = (_ENV or (getfenv and getfenv()) or _G)

--* LuaState *--
local LuaState = {}
function LuaState:new()
  local LuaStateInstance = {}

  LuaStateInstance.globalEnvironment = globalEnvironment -- Table for global variables
  LuaStateInstance.callFrameStack = {} -- Stack of call frames, each representing a function call
  LuaStateInstance.openUpvalues = {} -- List of open upvalues referring to active stack slots
  LuaStateInstance.errorJmp = nil -- Pointer to top of error recovery jump list
  LuaStateInstance.gc = {} -- State of garbage collector
  LuaStateInstance.currentWhite = {} -- Current "white" color for garbage collector

  return LuaStateInstance
end

return LuaState