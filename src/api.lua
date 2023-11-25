--[[
  Name: api.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
  Description:
    A simple API for the entire project.
    This is the only file that should be exposed to the user.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("api")

local Formats = ModuleManager:loadModule("Formats/Formats")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local Assembler = ModuleManager:loadModule("Assembler/Assembler")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/MathParser")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = ModuleManager:loadModule("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local ASTToTokensConverter = ModuleManager:loadModule("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local ASTObfuscator = ModuleManager:loadModule("Obfuscator/ASTObfuscator/ASTObfuscator")
local VirtualMachine = ModuleManager:loadModule("VirtualMachine/VirtualMachine")
local Beautifier = ModuleManager:loadModule("Beautifier/Beautifier")
local Minifier = ModuleManager:loadModule("Minifier/Minifier")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")
local ASTExecutor = ModuleManager:loadModule("ASTExecutor/ASTExecutor")
local ASTAnalyzer = ModuleManager:loadModule("StaticAnalyzer/ASTAnalyzer/ASTAnalyzer")
local ASTHierarchy = ModuleManager:loadModule("ASTHierarchy/ASTHierarchy")
local CodePhantom = ModuleManager:loadModule("Obfuscator/CodePhantom/CodePhantom")
local Printer = ModuleManager:loadModule("Printer/Printer")
local ASTOptimizer = ModuleManager:loadModule("Optimizer/ASTOptimizer/ASTOptimizer")
local SyntaxHighlighter = ModuleManager:loadModule("Interpreter/LuaInterpreter/SyntaxHighlighter/SyntaxHighlighter")

--* Export standard library functions *--
local unpack = (unpack or table.unpack)

--* API *--
local API = {
  VirtualMachine = {},
  Interpreter = {},
  InstructionGenerator = {},
  Assembler = {},
  MathParser = {},
  ASTExecutor = {},
  Beautifier = {},
  Minifier = {},
  ASTToTokensConverter = {},
  LuaState = {},
  ASTHierarchy = {},
  CodePhantom = {}, -- To be moved
  Optimizer = {
    ASTOptimizer = {}
  },

  -- Expose modules for easier access in the future
  Modules = {
    Formats              = Formats,
    Helpers              = Helpers,
    Assembler            = Assembler,
    Lexer                = Lexer,
    MathParser           = MathParser,
    Parser               = Parser,
    InstructionGenerator = InstructionGenerator,
    ASTToTokensConverter = ASTToTokensConverter,
    ASTObfuscator        = ASTObfuscator,
    VirtualMachine       = VirtualMachine,
    Beautifier           = Beautifier,
    Minifier             = Minifier,
    ASTExecutor          = ASTExecutor,
    ASTAnalyzer          = ASTAnalyzer,
    ASTHierarchy         = ASTHierarchy,
    Printer              = Printer,
    ASTOptimizer         = ASTOptimizer,
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

--* API.MathParser *--

--- Tokenizes an expressions and returns its tokens.
-- @param <string> expression An expression.
-- @return <table> tokens The tokens of an expression.
function API.MathParser.Tokenize(expression)
  assert(type(expression) == "string", "Expected string for argument 'expression', but got " .. type(expression))

  local tokens = MathParser:tokenize(expression)
  return tokens
end

--- Tokenizes, and parses an expressions and returns its Abstract Syntax Tree.
-- @param <string> expression An expression.
-- @return <table> AST The Abstract Syntax Tree of an expression.
function API.MathParser.Parse(expression)
  assert(type(expression) == "string", "Expected string for argument 'expression', but got " .. type(expression))

  local tokens = API.MathParser.Tokenize(expression)
  local AST = MathParser:parse(tokens)
  return AST
end

--- Tokenizes, parses, and evaluates an expressions and returns its result.
-- @param <string> expression An expression.
-- @return <any> result The result of the expression.
function API.MathParser.Evaluate(expression)
  assert(type(expression) == "string", "Expected string for argument 'expression', but got " .. type(expression))

  local AST = API.MathParser.Parse(expression)
  local result = MathParser:evaluate(AST)
  return result
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
  local beautifiedScript = Beautifier:new(AST):run()
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

  local tokens = ASTToTokensConverter:new(AST):run()
  return tokens
end

--* API.LuaState *--

--- Create a new LuaState object.
-- @return <table> luaState The LuaState object.
function API.LuaState.NewLuaState()
  local luaState = LuaState:new()
  return luaState
end

--* API.ASTHierarchy *--

--- Convert the given Abstract Syntax Tree to ASTHierarchy object and return it
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> astHierarchy The ASTHierarchy object of the Abstract Syntax Tree.
function API.ASTHierarchy.ConvertAST(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local astHierarchy = ASTHierarchy:new(AST):convert()
  return astHierarchy
end

--* API.CodePhantom *--

--- Convert the given luaState to obfuscated script and return it
-- @param <table> luaState The LuaState object.
-- @return <string> obfuscatedScript The obfuscated script.
function API.CodePhantom.ObfuscateState(luaState)
  assert(type(luaState) == "table", "Expected table for argument 'luaState', but got " .. type(luaState))

  local obfuscatedScript = CodePhantom:new(luaState):run()
  return obfuscatedScript
end

--- Convert the given script to obfuscated script and return it
-- @param <string> script The Lua script to obfuscate.
-- @return <string> obfuscatedScript The obfuscated script.
function API.CodePhantom.ObfuscateScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local luaState = API.InstructionGenerator.ConvertToInstructions(AST)
  local obfuscatedScript = CodePhantom:new(luaState):run()
  return obfuscatedScript
end

--* API.Optimizer.ASTOptimizer *--

--- Convert the given script to an AST, optimize and return it
-- @param <string> script The Lua script to optimize.
-- @return <table> optimizedAST The optimized Abstract Syntax Tree.
function API.Optimizer.ASTOptimizer.OptimizeScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local astHierarchy = API.ASTHierarchy.ConvertAST(AST)
  local optimizedAST = ASTOptimizer:new(astHierarchy):run()
  return optimizedAST
end

--- Convert the given ASTHierarchy object to an optimized AST and return it
-- @param <table> astHierarchy The ASTHierarchy object.
-- @return <table> optimizedAST The optimized Abstract Syntax Tree.
function API.Optimizer.ASTOptimizer.OptimizeASTHierarchy(astHierarchy)
  assert(type(astHierarchy) == "table", "Expected table for argument 'astHierarchy', but got " .. type(astHierarchy))

  local optimizedAST = ASTOptimizer:new(astHierarchy):run()
  return optimizedAST
end

return API