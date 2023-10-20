--[[
  Name: Debugger.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Debugger/Debugger")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local createTableDecorator = Helpers.CreateTableDecorator
local insert = table.insert
local concat = table.concat
local find = table.find or Helpers.TableFind

--* Debugger *--
local Debugger = {}

local function hookMethods(class, debugInfo)
  local classDecorator = createTableDecorator(class)
  for _, v in ipairs(debugInfo) do
    local event = v.event
    local logType = v.logType
    classDecorator:__AddEvent(event, function(self, index, value)
      if index:sub(0, #"__Debug") == "__Debug" then return end
      insert(class.__Debug_log[logType], {
        Index = index,
        Value = value or class[index],
        Traceback = debug.traceback()
      })
    end)
  end

  return classDecorator
end

function Debugger:injectDebugger(class)
  class.__Debug_log = { Calls = {}, Index = {}, NewIndex = {} }
  function class:__Debug_getLog()
    local lines = {}
    local function formatLog(logType)
      for i, v in ipairs(self.__Debug_log[logType]) do
        insert(lines, logType .. " #" .. i .. ":")
        for key, value in pairs(v) do
          value = Helpers.SerializeValue(value)
          insert(lines, "  " .. key .. ": " .. value:gsub("\n", "\n  "))
        end
      end
    end

    formatLog("Calls")
    formatLog("Index")
    formatLog("NewIndex")

    return concat(lines, "\n")
  end

  function class:__Debug_saveLogToFile(fileName)
    local file = io.open(fileName, "w")
    file:write(self:__Debug_getLog())
    file:close()
  end

  function class:__Debug_printLog()
    print("Printing Debug Log:")
    print(self:__Debug_getLog())
  end


  local classDecorator = hookMethods(class, {{event = "Index", logType = "Index"}, {event = "NewIndex", logType = "NewIndex"}})

  for index, func in pairs(class) do
    if type(func) == "function" and index:sub(0, #"__Debug") ~= "__Debug" then
      class[index] = function(...)
        local args = {...}
        local formattedArgs = {...}

        if args[1] == class or args[1] == classDecorator then
          args[1], formattedArgs[1] = classDecorator, "self"
        end

        local tb = {pcall(func, unpack(args))}
        local functionInfo = debug.getinfo(func)
        functionInfo.namewhat = index

        insert(class.__Debug_log.Calls, {
          Arguments = formattedArgs,
          FunctionInfo = functionInfo,
          Traceback = debug.traceback(),
          ReturnValues = {select(2, unpack(tb))}
        })

        if not tb[1] then
          class:__Debug_printLog()
          error(select(2, unpack(tb)))
        end

        return select(2, unpack(tb))
      end
    end
  end
end


return Debugger