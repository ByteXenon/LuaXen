--[[
  Name: lua.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--local Interpreter = require("Interpreter/Main")
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("lua")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local ASTToTokensConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")
local Beautifier = ModuleManager:loadModule("Beautifier/Beautifier")
local Minifier = ModuleManager:loadModule("Minifier/Minifier")
local ASTExecutor = ModuleManager:loadModule("ASTExecutor/ASTExecutor")
local ASTObfuscator = ModuleManager:loadModule("Obfuscator/ASTObfuscator/ASTObfuscator")


local lua = {
  optionSwitches = {},
  includes = {},
  COPYRIGHT = "Lua 5.1.5  Copyright (C) 2023",
  VERSION   = "Lua 5.1"
}
lua.params = {
  ["-e"] = {{"stat"}, "execute string 'stat'",                            lua.executeString},
  ["-l"] = {{"name"}, "require library 'name'",                           lua.includeLibrary},
  ["-i"] = {nil,     "enter interactive mode after executing 'script'", lua.interactiveMode},
  ["-v"] = {nil,     "show version information",                        lua.printVersion},
  ["--"] = {nil,     "stop handling options"},
  ["-"] =  {nil,     "execute stdin and stop handling options"}
}

function lua.printHelp()
  local lines = {}
  for index, param in pairs(lua.params) do
    local args = (param[1] and table.concat(param[1], ", ")) or ""
    local description = param[2] or ""

    table.insert(lines, {"  ", index, "  ", argName, "  ", description})
  end

  print("usage: lua [options] [script [args]].")
  print("Available options are:")
  Helpers.PrintAligned(Lines)
end

function lua.printVersion()
  print(lua.COPYRIGHT)
end

function lua.interactiveMode()

end

function lua.parseArgs(args)
  local fileName;
  local fileVarArgs = {};
  local optionCalls = {}

  local argIndex = 1;
  while args[argIndex] do
    local currentArg = args[argIndex]
    if lua.params[currentArg] and not optionCalls[currentArg] then
      local optionProperties = lua.params[currentArg]
      local args = optionProperties[1]
      local consumedArgs = {}
      for index = argIndex + 1, argIndex + 1 + (#(args or {})) do
        local newArg = args[index]
        if not newArg then error() end
        table.insert(consumedArgs, newArg)
      end
      optionCalls[currentArg] = consumedArgs
    else
      if not fileName then fileName = currentArg
      else insert(fileVarArgs, currentArg) end
    end

    argIndex = argIndex + 1
  end
  for optionName, arguments in pairs(optionCalls) do
    lua.params[optionName][3](unpack(arguments))
  end
  if fileName then
    lua.executeFile(fileName, fileVarArgs)
  end

end

function lua.executeString(string)
  local tokens = Lexer:new(string):tokenize()
  local AST = Parser:new(tokens):parse()
  return ASTExecutor:new(AST):execute()
end

function lua.executeFile(filename)
  local file = io.open(filename, "r")
  local contents = file:read("*a")
  file:close()
  return lua.executeString(contents)
end

lua.parseArgs({...})