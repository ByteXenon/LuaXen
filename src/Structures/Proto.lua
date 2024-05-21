--[[
  Name: Proto.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-11
  Description:
    This file defines the Proto structure used in the Lua interpreter.
    A Proto (short for prototype) represents a Lua function's prototype,
    which includes its bytecode, constants, upvalues, and other function-specific information.
    Proto structures are created during the parsing and compilation phase of a Lua script.
    Each Proto represents the static structure of a function in the code.
--]]

--* Proto *--
local Proto = {}
function Proto:new()
  local ProtoInstance = {}

  ProtoInstance.source = "nil"        -- The source file where the function is defined
  ProtoInstance.lineDefined = -1      -- The line number where the function is defined
  ProtoInstance.lastLineDefined = -1  -- The line number where the function ends
  ProtoInstance.numParams = 0         -- The number of fixed parameters the function takes
  ProtoInstance.numUpvalues = 0       -- The number of upvalues the function uses (aka numps)
  ProtoInstance.isVararg = false      -- A flag indicating whether the function takes a variable number of arguments
  ProtoInstance.maxStackSize = 1      -- The maximum stack size needed by the function
  -- ProtoInstance.code = nil         -- The bytecode of the function

  ProtoInstance.instructions = {}     -- Used instead of bytecode
  ProtoInstance.constants = {}        -- The constants used by the function
  ProtoInstance.register = {}         -- The register used by the function
  ProtoInstance.upvalues = {}         -- The upvalues used by the function
  ProtoInstance.protos = {}           -- The function's inner functions
  ProtoInstance.lineInfo = {}         -- Debugging information about the function's lines
  -- ProtoInstance.localVariables = nil  -- Debugging information about the function's local variables
  -- ProtoInstance.upvalueNames = nil    -- Debugging information about the function's upvalues

  return ProtoInstance
end

return Proto