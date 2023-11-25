--[[
  Name: lua.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    This module serves as a Lua interpreter, providing functionalities such as executing Lua scripts
    from a string or a file, entering interactive mode, and parsing command line arguments.
    It also handles different Lua interpreter options and prints help and version information.
--]]

--* Dependencies *--
local API = require("api")

local Formats =           API.Modules.Formats
local Helpers =           API.Modules.Helpers
local SyntaxHighlighter = API.Modules.SyntaxHighlighter

--* Export library functions *--
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* lua *--
local lua = {
  optionSwitches = {},
  includes = {},
  COPYRIGHT = "Lua 5.1.5 Copyright (C) 2023, ByteXenon & Friends",
  VERSION   = "Lua 5.1"
}
lua.params = {
  ["-e"] = {{"stat"}, "execute string 'stat'",                            lua.executeString},
  ["-l"] = {{"name"}, "require library 'name'",                           lua.includeLibrary},
  ["-i"] = {nil,     "enter interactive mode after executing 'script'",   lua.interactiveMode},
  ["-v"] = {nil,     "show version information",                          lua.printVersion},
  ["--"] = {nil,     "stop handling options"},
  ["-"] =  {nil,     "execute stdin and stop handling options"}
}

--- Prints the help message for the Lua interpreter.
function lua.printHelp()
  local lines = {}
  for index, param in pairs(lua.params) do
    local args = (param[1] and concat(param[1], ", ")) or ""
    local description = param[2] or ""

    insert(lines, {"  ", index, "  ", argName, "  ", description})
  end

  print("usage: lua [options] [script [args]].")
  print("Available options are:")
  Helpers.PrintAligned(lines)
end

--- Prints the version information for the Lua interpreter.
function lua.printVersion()
  print(lua.COPYRIGHT)
end

--- Enters interactive mode for the Lua interpreter.
function lua.interactiveMode()
  lua.printVersion()
  local globalLuaState = API.LuaState.NewLuaState()
  while (true) do
    io.write(Formats.formatString(">(blue)<>>> >(reset)<"))
    local input = io.stdin:read("*l")
    if input == "exit" then break end
    local tokensWithAdditionalInfo = API.Interpreter.ConvertToTokens(input, true)
    local coloredCode = SyntaxHighlighter:new(tokensWithAdditionalInfo):getFormattedTokens()
    print(Formats.formatString(">(up(1))<>(clear_line)<>(blue)<>>> >(reset)<") .. coloredCode)

    API.ASTExecutor.ExecuteScript(input, globalLuaState)
  end
end

--- Parses the command line arguments for the Lua interpreter.
-- @param args The command line arguments.
function lua.parseArgs(args)
  assert(type(args) == "table", "args must be a table")

  if #args == 0 then lua.interactiveMode() end
  local fileName
  local fileVarArgs = {}
  local optionCalls = {}

  for argIndex = 1, #args do
    local currentArg = args[argIndex]

    -- Handle help request
    if currentArg == "-h" or currentArg == "--help" then
      return lua.printHelp()
    end

    -- Handle options with parameters
    if lua.params[currentArg] and not (optionCalls[currentArg]) then
      local optionProperties = lua.params[currentArg]
      local optionArgs = optionProperties[1] or {}
      local consumedArgs = {}

      for index = argIndex + 1, argIndex + #optionArgs do
        local newArg = args[index]
        if not newArg then error("Missing argument for option " .. currentArg) end
        insert(consumedArgs, newArg)
      end

      optionCalls[currentArg] = consumedArgs
      argIndex = argIndex + #optionArgs -- Skip consumed arguments
    else
      -- Handle file name and variable arguments
      if not fileName then
        fileName = currentArg
      else
        insert(fileVarArgs, currentArg)
      end
    end
  end

  -- Execute options with parameters
  for optionName, arguments in pairs(optionCalls) do
    lua.params[optionName][3](unpack(arguments))
  end

  -- Execute file if provided
  if fileName then
    lua.executeFile(fileName, unpack(fileVarArgs))
  end
end

--- Executes a Lua script from a string.
-- @param string The Lua script as a string.
-- @param varArgs The variable arguments to pass to the script.
function lua.executeString(string, varArgs)
  assert(type(string) == "string", "string must be a string")

  -- Use the AST executor for now
  -- - Because the AST - instructions converter is
  -- too buggy at this moment
  return API.ASTExecutor.ExecuteScript(script)
end

--- Executes a Lua script from a file.
-- @param filename The name of the file containing the Lua script.
-- @param varArgs The variable arguments to pass to the script.
function lua.executeFile(filename, varArgs)
  assert(type(filename) == "string", "filename must be a string")

  local file = io.open(filename, "r")
  local contents = file:read("*a")
  file:close()
  return lua.executeString(contents, varArgs)
end

lua.parseArgs({...})