local Helpers = require("Helpers/Helpers")

-- Import the required API
local luaAPI = require("api")

local fakeModuleManager = {
  newFile = function()
    return {
      loadModule = function(self, path)
        return _G.require(path)
      end
    }
  end
}

-- ASTExecutor
do

  local loadedModules = {}
  local normalRequire = require
  local fakeRequire = function(path)
    local fullPath = path .. ".lua"
    if fullPath == "ModuleManager/ModuleManager.lua" then
      return fakeModuleManager
    end
    if loadedModules[fullPath] then
      return loadedModules[fullPath]
    end
    -- print("Loading module: " .. fullPath)
    local returnVal = luaAPI.ASTExecutor.ExecuteScript(Helpers.ReadFile(fullPath), nil, nil, fullPath)
    loadedModules[fullPath] = returnVal
    return returnVal
  end

  _G.getfenv = function()
    return _G
  end
  _G.require = fakeRequire

  -- Convert the Lua code into an Abstract Syntax Tree (AST)
  local AST = luaAPI.Interpreter.ConvertToAST(Helpers.ReadFile("lua.lua"))

  -- Execute the AST directly without using the Virtual Machine
  luaAPI.ASTExecutor.Execute(AST)
end