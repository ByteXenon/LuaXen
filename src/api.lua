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
local Minifier = require("Minifier/Minifier")
local Packer = require("Packer/Packer")
local LuaState = require("Structures/LuaState")
local ASTExecutor = require("ASTExecutor/ASTExecutor")
local Printer = require("Printer/Printer")
local ASTPrinter = require("Printer/ASTPrinter/ASTPrinter")
local SyntaxHighlighter = require("Interpreter/LuaInterpreter/SyntaxHighlighter/SyntaxHighlighter")
local ASTObfuscator = require("Obfuscator/AST/ASTObfuscator")
local IronBrikked = require("Obfuscator/IronBrikked/IronBrikked")

--* Imports *--
local unpack = (unpack or table.unpack)

--* API *--
local API = {
  VirtualMachine = {},
  Interpreter = {},
  InstructionGenerator = {},
  Assembler = {},
  ASTExecutor = {},
  Minifier = {},
  ASTToTokensConverter = {},
  Printer = {
    TokenPrinter = {},
    ASTPrinter = {}
  },
  Packer = {},
  LuaState = {},
  Obfuscator = {
    ASTObfuscator = {},
    IronBrikked = {}
  },

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
    Minifier             = Minifier,
    Packer               = Packer,
    ASTExecutor          = ASTExecutor,
    Printer              = Printer,
    ASTPrinter           = ASTPrinter,
    SyntaxHighlighter    = SyntaxHighlighter,
    ASTObfuscator        = ASTObfuscator,
    IronBrikked          = IronBrikked
  }
}

--* API.VirtualMachine *--

--- Executes a provided proto in a virtual machine.
-- @param <LuaProto> proto The proto of a Lua script.
-- @param <boolean> debug Whether to run in debug mode or not.
function API.VirtualMachine.ExecuteProto(proto, debug)
  assert(type(proto) == "table", "Expected table for argument 'proto', but got " .. type(proto))

  local newVirtualMachine = VirtualMachine:new(proto, debug)
  newVirtualMachine:run()
end

--- Executes a provided script in a virtual machine.
-- @param <string> script A Lua script.
-- @param <boolean> debug Whether to run in debug mode or not.
function API.VirtualMachine.ExecuteScript(script, debug)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local luaProto = API.Interpreter.ConvertToInstructions(script)
  API.VirtualMachine.ExecuteProto(luaProto, debug)
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

--- Tokenizes, parses, and converts Lua script to instructions and returns its proto.
-- @param <string> script A Lua script.
-- @return <table> proto The proto of a Lua script.
function API.Interpreter.ConvertToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local proto = InstructionGenerator:new(AST):run()
  return proto
end

--* API.InstructionGenerator *--

--- Converts AST to instructions and returns its proto.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> proto The proto of a Lua script.
function API.InstructionGenerator.ConvertASTToInstructions(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local proto = InstructionGenerator:new(AST):run()
  return proto
end

--- Converts Lua script to instructions and returns its proto.
-- @param <string> script A Lua script.
-- @return <table> proto The proto of a Lua script.
function API.InstructionGenerator.ConvertScriptToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local proto = API.InstructionGenerator.ConvertASTToInstructions(AST)
  return proto
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

--- Tokenizes and Parses code and returns its proto.
-- @param <string> code Assembly code.
-- @return <table> proto The proto of the code.
function API.Assembler.Parse(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local tokens = Assembler:tokenize(code)
  local proto = Assembler:parse(tokens)
  return proto
end

--- Executes assembly code
-- @param <string> code Assembly code.
-- @return <any> returnValue The return value of the assembly code.
function API.Assembler.Execute(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local proto = API.Assembler.Parse(code)
  return API.VirtualMachine.ExecuteProto(proto)
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

--* API.Minifier *--

--- Minify an Abstract Syntax Tree.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> minifiedAST The minified Abstract Syntax Tree.
function API.Minifier.MinifyAST(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local minifiedAST = Minifier:new(AST):run()
  return minifiedAST
end

--- Minify a Lua script.
-- @param <string> script A Lua script.
-- @return <table> minifiedAST The minified Abstract Syntax Tree.
function API.Minifier.MinifyScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local minifiedAST = API.Minifier.MinifyAST(AST)
  return minifiedAST
end

--* API.Packer *--

--- Pack all `require` calls in an Abstract Syntax Tree.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @param <string?> localizedPath The localized path of require calls.
-- @return <table> packedAST The packed Abstract Syntax Tree.
function API.Packer.PackAST(AST, localizedPath)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local packedAST = Packer:new(AST, localizedPath):pack()
  return packedAST
end

--- Pack all `require` calls in one Lua script.
-- @param <string> script A Lua script.
-- @param <string?> localizedPath The localized path of require calls.
-- @return <table> packedAST The packed Abstract Syntax Tree.
function API.Packer.PackScript(script, localizedPath)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local packedAST = API.Packer.PackAST(AST, localizedPath)
  return packedAST
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

--* API.Printer.TokenPrinter *--

--- Print tokens of a Lua script.
-- @param <table> tokens The tokens of a Lua script.
-- @return <string> script The Lua script.
function API.Printer.TokenPrinter.PrintTokens(tokens)
  assert(type(tokens) == "table", "Expected table for argument 'tokens', but got " .. type(tokens))

  local script = Printer:new(tokens):run()
  return script
end

--- Convert a Lua script to tokens and print them.
-- @param <string> script A Lua script.
-- @return <string> script The Lua script.
function API.Printer.TokenPrinter.PrintScriptTokens(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local tokens = API.Interpreter.ConvertToTokens(script)
  local script = API.Printer.TokenPrinter.PrintTokens(tokens)
  return script
end

--* API.Printer.ASTPrinter *--

--- Print an Abstract Syntax Tree.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <string> script The Lua script.
function API.Printer.ASTPrinter.PrintAST(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local script = ASTPrinter:new(AST):print()
  return script
end

--- Convert a Lua script to an Abstract Syntax Tree and print it.
-- @param <string> script A Lua script.
-- @return <string> script The Lua script.
function API.Printer.ASTPrinter.PrintScriptAST(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local script = API.Printer.ASTPrinter.PrintAST(AST)
  return script
end

--* API.Obfuscator *--

--* API.Obfuscator.ASTObfuscator *--

--- Obfuscate an Abstract Syntax Tree.
-- @param <table> ast The Abstract Syntax Tree of a Lua script.
-- @return <table> obfuscatedAST The obfuscated Abstract Syntax Tree.
function API.Obfuscator.ASTObfuscator.ObfuscateAST(ast)
  assert(type(ast) == "table", "Expected table for argument 'ast', but got " .. type(ast))

  local obfuscatedAST = ASTObfuscator:new(ast):obfuscate()
  -- Convert that ast to tokens -> code -> ast
  -- because we need to update the ast with new metadata
  -- and it's currently the only way to do that
  local obfuscatedASTTokens = ASTToTokensConverter:new(obfuscatedAST):convert()
  local obfuscatedCode = Printer:new(obfuscatedASTTokens):run()
  local obfuscatedAST = API.Interpreter.ConvertToAST(obfuscatedCode)

  return obfuscatedAST
end

--- Obfuscate a Lua script.
-- @param <string> script A Lua script.
-- @return <string> obfuscatedScript The obfuscated version of the given Lua script.
function API.Obfuscator.ASTObfuscator.ObfuscateScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local obfuscatedAST = API.Obfuscator.ASTObfuscator.ObfuscateAST(AST)
  local obfuscatedASTTokens = ASTToTokensConverter:new(obfuscatedAST):convert()
  local obfuscatedScript = Printer:new(obfuscatedASTTokens):run()
  return obfuscatedScript
end

--* API.Obfuscator.IronBrikked *--

--- Obfuscate a Lua prototype.
-- @param <table> proto A Lua prototype.
-- @return <string> obfuscatedCode The obfuscated version of the given Lua prototype.
function API.Obfuscator.IronBrikked.ObfuscateProto(proto)
  assert(type(proto) == "table", "Expected table for argument 'proto', but got " .. type(proto))

  local obfuscatedCode = IronBrikked:new(proto):obfuscate()
  return obfuscatedCode
end

--- Obfuscate a Lua script.
-- @param <string> script A Lua script.
-- @return <string> obfuscatedScript The obfuscated version of the given Lua script.
function API.Obfuscator.IronBrikked.ObfuscateScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local proto = API.InstructionGenerator.ConvertScriptToInstructions(script)
  local obfuscatedScript = API.Obfuscator.IronBrikked.ObfuscateProto(proto)
  return obfuscatedScript
end

--* API.LuaState *--

--- Create a new LuaState object.
-- @return <table> luaState The LuaState object.
function API.LuaState.NewLuaState()
  local luaState = LuaState:new()
  return luaState
end

return API