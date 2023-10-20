-- Import the required API
local luaAPI = require("api")

-- Assembler
do
  -- Parse the assembly code into a Lua state
  local luaState = luaAPI.Assembler.Parse([[
    ; Define a function that prints a message
    _my_func: {
      GETGLOBAL 0, "print"
      LOADK 1, "Hello, world!"
      CALL 0, 2, 1
    }

    ; Create a closure for the function and call it
    CLOSURE 0, _my_func
    CALL 0, 1, 1
  ]])

  -- Execute the Lua state
  luaAPI.VirtualMachine.ExecuteState(luaState)
end

-- Interpreter
do
  -- Convert the Lua code into instructions and create a Lua state
  local luaScriptState = luaAPI.Interpreter.ConvertToInstructions([[
    -- Define a function
    local function _my_func()
      print("Hello, world!")
    end

    _my_func()
  ]])

  -- Execute the Lua state
  luaAPI.VirtualMachine.ExecuteState(luaScriptState)
end

-- ASTExecutor
do
  -- Convert the Lua code into an Abstract Syntax Tree (AST)
  local AST = luaAPI.Interpreter.ConvertToAST([[
    local function _my_func(arg1)
      print("Test argument #1: " .. tostring(arg1))
    end
    _my_func("'hello!'")
  ]])

  -- Execute the AST directly without using the Virtual Machine
  luaAPI.ASTExecutor.Execute(AST)
end