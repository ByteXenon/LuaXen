-- Import the required API
local luaAPI = require("api")

-- Assembler
do
  -- Parse the assembly code into a Lua state
  local luaState = luaAPI.Assembler.Parse([[
    PRINT_FUNC: "print"
    PRINT_MSG: "Hello, world!"

    ; Define a function that prints a message
    _my_func: {
      GETGLOBAL 0, PRINT_FUNC
      LOADK 1, PRINT_MSG
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
    print("Hello, world!")
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