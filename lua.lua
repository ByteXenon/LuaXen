--[[
  Name: lua.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--local Interpreter = require("Interpreter/Main")
local ModuleManager = require("ModuleManager/ModuleManager")

local Parser = require("Parser/Main")
local VirtualMachine = require("VirtualMachine/Main")
local Helpers = require("Helpers/Helpers")
local OPCodes = require("OPCodes/Main")
local Optimizer = require("Optimizer/Main")

local lua = {
  option_switches = {},
  includes = {},
  COPYRIGHT = "Lua 5.1.5  Copyright (C) 2023"
}

function lua.print_help()
  local Lines = {}
  for Index, Param in ipairs(lua.params) do
    local Commands = table.concat(Param[1], ", ")
    local ArgName = Param[2] or ''
    local Description = Param[3] or ''

    table.insert(Lines, {"  ", Commands, "  ", ArgName, "  ", Description})
  end

  print("usage: lua [options] [script [args]].")
  print("Available options are:")
  Helpers.PrintAligned(Lines)
end

function lua.print_version()
  print(lua.COPYRIGHT)
end

function lua.interactive_mode()

end

function lua.parse_args(args)
  local file_names = {}
  local switch_functions = {}

  local arg_index = 1
  while args[arg_index] do
    local arg = args[arg_index]
    
    local is_argument = (arg:sub(1, 1) == "-")
    if not is_argument then
      arg_index = arg_index + 1
      table.insert(file_names, args[arg_index])
    else
      local is_valid_command = false
      for __, param in ipairs(lua.params) do
        for _, command in ipairs(param[1]) do
          local is_matched = (arg == command)
          if is_matched then
            is_valid_command = true
            local switch_name = param[4]
            if not switch_name then
              local param_function = param[5]
              arg_index = arg_index + 1
              param_function(args[arg_index])
            elseif switch_name and not lua.option_switches[command] then
              lua.option_switches[command] = true
              table.insert(switch_functions, param[5])
            end
            break
          end
        end
      end

      if not is_valid_command then
        lua.print_help()
      end
    end
    arg_index = arg_index + 1
  end

  for _, func in ipairs(switch_functions) do func() end
end

function lua.execute_string(string)
  return string
end

function lua.execute_file(filename)
  
end

lua.params = {
  {{"-e"}, "stat", "execute string 'stat'",                           nil,                       lua.execute_string},
  {{"-l"}, "name", "require library 'name'",                          nil,                       lua.include_library},
  {{"-i"}, "",     "enter interactive mode after executing 'script'", "toggle_interactive_mode", lua.interactive_mode},
  {{"-v"}, "",     "show version information",                        "print_version",           lua.print_version},
  {{"--"}, "",     "stop handling options"},
  {{"-"},  "",     "execute stdin and stop handling options"}
}

lua.parse_args({...})