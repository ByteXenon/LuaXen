--[[
  Name: api.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
  Description:
    A simple API for the entire project.
    This is the only file that should be exposed to the user.

  Read the license file in the root of the project directory.
--]]

--* Dependencies *--
local AnsiFormatter = require("AnsiFormatter/AnsiFormatter")
local Helpers = require("Helpers/Helpers")
local Assembler = require("Assembler/Assembler")
local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = require("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local ASTToTokensConverter = require("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local VirtualMachine = require("VirtualMachine/VirtualMachine")
local Beautifier = require("Beautifier/Beautifier")
local Minifier = require("Minifier/Minifier")
local Packer = require("Packer/Packer")
local LuaState = require("Structures/LuaState")
local ASTExecutor = require("ASTExecutor/ASTExecutor")
local Printer = require("Printer/Printer")
local SyntaxHighlighter = require("Interpreter/LuaInterpreter/SyntaxHighlighter/SyntaxHighlighter")

--* Imports *--
local unpack = (unpack or table.unpack)

--* API *--
local API = {
  VirtualMachine = {},
  Interpreter = {},
  InstructionGenerator = {},
  Assembler = {},
  ASTExecutor = {},
  Beautifier = {},
  Minifier = {},
  ASTToTokensConverter = {},
  Printer = {},
  Packer = {},
  LuaState = {},

  -- Expose modules for easier access in the future
  Modules = {
    AnsiFormatter        = AnsiFormatter,
    Helpers              = Helpers,
    Assembler            = Assembler,
    Lexer                = Lexer,
    Parser               = Parser,
    InstructionGenerator = InstructionGenerator,
    ASTToTokensConverter = ASTToTokensConverter,
    VirtualMachine       = VirtualMachine,
    Beautifier           = Beautifier,
    Minifier             = Minifier,
    Packer               = Packer,
    ASTExecutor          = ASTExecutor,
    Printer              = Printer,
    SyntaxHighlighter    = SyntaxHighlighter
  }
}

--* API.VirtualMachine *--

--- Executes a provided state in a virtual machine.
-- @param <LuaState> state The state of a Lua script.
-- @param <boolean> debug Whether to run in debug mode or not.
function API.VirtualMachine.ExecuteState(state, debug)
  assert(type(state) == "table", "Expected table for argument 'state', but got " .. type(state))

  local newVirtualMachine = VirtualMachine:new(state, debug)
  newVirtualMachine:run()
end

--- Executes a provided script in a virtual machine.
-- @param <string> script A Lua script.
-- @param <boolean> debug Whether to run in debug mode or not.
function API.VirtualMachine.ExecuteScript(script, debug)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local luaState = API.Interpreter.ConvertToInstructions(script)
  API.VirtualMachine.ExecuteState(luaState, debug)
end

--* API.Interpreter *--

--- Tokenizes a Lua script and returns its tokens.
-- @param <string> script A Lua script.
-- @param <boolean> includeHighlightTokens Whether to include additional highlight tokens or not.
-- @return <table> tokens The tokens of the Lua script.
function API.Interpreter.ConvertToTokens(script, includeHighlightTokens)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local tokens = Lexer:new(script, includeHighlightTokens):tokenize()
  return tokens
end

--- Tokenizes and parses Lua script and returns its Abstract Syntax Tree.
-- @param <string> script A Lua script.
-- @return <table> AST The Abstract Syntax Tree of the Lua script.
function API.Interpreter.ConvertToAST(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local tokens = API.Interpreter.ConvertToTokens(script)
  local AST = Parser:new(tokens):parse()
  return AST
end

--- Tokenizes, parses, and converts Lua script to instructions and returns its state.
-- @param <string> script A Lua script.
-- @return <table> state The state of a Lua script.
function API.Interpreter.ConvertToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local state = InstructionGenerator:new(AST):run()
  return state
end

--* API.InstructionGenerator *--

--- Converts AST to instructions and returns its state.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> state The state of a Lua script.
function API.InstructionGenerator.ConvertASTToInstructions(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local state = InstructionGenerator:new(AST):run()
  return state
end

--- Converts Lua script to instructions and returns its state.
-- @param <string> script A Lua script.
-- @return <table> state The state of a Lua script.
function API.InstructionGenerator.ConvertScriptToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local state = API.InstructionGenerator.ConvertASTToInstructions(AST)
  return state
end

--* API.Assembler *--

--- Tokenizes code and returns its tokens.
-- @param <string> code Assembly code.
-- @return <table> tokens The tokens of an assembly code.
function API.Assembler.Tokenize(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local tokens = Assembler:tokenize(code)
  return tokens
end

--- Tokenizes and Parses code and returns its state.
-- @param <string> code Assembly code.
-- @return <table> state The state of the code.
function API.Assembler.Parse(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local tokens = Assembler:tokenize(code)
  local state = Assembler:parse(tokens)
  return state
end

--- Executes assembly code
-- @param <string> code Assembly code.
-- @return <any> returnValue The return value of the assembly code.
function API.Assembler.Execute(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local state = API.Assembler.Parse(code)
  return API.VirtualMachine.ExecuteState(state)
end

--* API.ASTExecutor *--

--- Execute an Abstract Syntax Tree and return its returned values.
-- @param <table> AST An Abstract Syntax Tree of a Lua script.
-- @param <table?> state The state of a Lua script.
-- @param <boolean?> debug Whether to run in debug mode or not.
-- @param <string?> scriptName The name of the script.
-- @return <...any> returnValue The return value of the AST.
function API.ASTExecutor.Execute(AST, state, debug, scriptName)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local returnValues = { ASTExecutor:new(AST, state, debug, scriptName):execute() }
  return unpack(returnValues)
end

--- Execute a script using Abstarct Syntax Tree executor and return its returned values.
-- @param <string> script A script to execute.
-- @param <table?> state The state of a Lua script.
-- @param <boolean?> debug Whether to run in debug mode or not.
-- @param <string?> scriptName The name of the script.
-- @return <...any> returnValue The return value of the Lua script.
function API.ASTExecutor.ExecuteScript(script, state, debug, scriptName)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local returnValues = { ASTExecutor:new(AST, state, debug, scriptName):execute() }
  return unpack(returnValues)
end

--* API.Beautifier *--

--- Beautify a Lua script.
-- @param <string> script A Lua script.
-- @return <string> beautifiedScript The beautified version of the given Lua script.
function API.Beautifier.Beautify(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local beautifiedScript = Beautifier:new(AST):beautify()
  return beautifiedScript
end

--- Beautify a Lua script from AST.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <string> beautifiedScript The beautified version of the given Lua script.
function API.Beautifier.BeautifyAST(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local beautifiedScript = Beautifier:new(AST):beautify()
  return beautifiedScript
end

--* API.Minifier *--

--- Minify a Lua script.
-- @param <string> script A Lua script.
-- @return <string> minifiedScript The minified version of the given Lua script.
function API.Minifier.Minify(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local minifiedScript = Minifier:new(AST):run()
  return minifiedScript
end

--* API.ASTToTokensConverter *--

--- Convert the given Abstract Syntax Tree to tokens and return it
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> tokens The tokens of the given Abstract Syntax Tree.
function API.ASTToTokensConverter.ConvertToTokens(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local tokens = ASTToTokensConverter:new(AST):convert()
  return tokens
end

--* API.Printer *--

--- Convert the given tokens to code.
-- @param <table> tokens The tokens of a Lua script.
-- @return <string> code The code of the given tokens.
function API.Printer.PrintTokens(tokens)
  assert(type(tokens) == "table", "Expected table for argument 'tokens', but got " .. type(tokens))

  local code = Printer:new(tokens):run()
  return code
end

--* API.LuaState *--

--- Create a new LuaState object.
-- @return <table> luaState The LuaState object.
function API.LuaState.NewLuaState()
  local luaState = LuaState:new()
  return luaState
end

return API