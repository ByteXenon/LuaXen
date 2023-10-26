--[[
  Name: lua.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local API = require("api")

--* Export library functions *--
local insert = table.insert
local concat = table.concat

--* lua *--
local lua = {
  optionSwitches = {},
  includes = {},
  COPYRIGHT = "Lua 5.1.5 Copyright (C) 2023",
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

function lua.printVersion()
  print(lua.COPYRIGHT)
end

function lua.interactiveMode()

end

function lua.parseArgs(args)
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
    if lua.params[currentArg] and not optionCalls[currentArg] then
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

function lua.executeString(string, varArgs)
  -- Use the AST executor for now
  -- - Because the AST - instructions converter is
  -- too buggy at this moment
  return API.ASTExecutor.ExecuteScript(script)
end

function lua.executeFile(filename, varArgs)
  local file = io.open(filename, "r")
  local contents = file:read("*a")
  file:close()
  return lua.executeString(contents, varArgs)
end

lua.parseArgs({...})