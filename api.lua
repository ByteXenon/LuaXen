--[[
  Name: api.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("api")

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
local ASTExecutor = ModuleManager:loadModule("ASTExecutor/ASTExecutor")
local ASTAnalyzer = ModuleManager:loadModule("StaticAnalyzer/ASTAnalyzer/ASTAnalyzer")
local ASTHierarchy = ModuleManager:loadModule("ASTHierarchy/ASTHierarchy")
local Printer = ModuleManager:loadModule("Printer/Printer")
local ASTOptimizer = ModuleManager:loadModule("Optimizer/ASTOptimizer/ASTOptimizer")

-- VirtualMachine:
---  ExecuteState(state)
---  ExecuteScript(script)
--
-- Interpreter:
---  ConvertToTokens(script)
---  ConvertToAST(script)
---  ConvertToInstructions(script)
--
-- Assembler:
---  Tokenize(code)
---  Parse(code)
--
-- MathParser:
---  Tokenize(expression)
---  Parse(expression)
---  Evaluate(expression)
--
-- ASTExecutor:
---  Execute(AST)
--
-- Beautifier:
---  Beautify(script)
--
-- Minifier:
---  Minify(script)
--
-- ASTToTokensConverter:
---  ConvertToTokens(AST)
--
-- LuaState:
---  NewLuaState()
--
-- ASTOptimizer:
---  ConvertAST(AST)
--
-- Optimizer.ASTOptimizer:
---  OptimizeScript(script)
---  OptimizeASTHierarchy(astHierarchy)


--* API *--
local API = {
  VirtualMachine = {},
  Interpreter = {},
  Assembler = {},
  MathParser = {},
  ASTExecutor = {},
  Beautifier = {},
  Minifier = {},
  ASTToTokensConverter = {},
  LuaState = {},
  ASTHierarchy = {},
  Optimizer = {
    ASTOptimizer = {}
  }
}


---------- API.VirtualMachine ----------

--- API.VirtualMachine.ExecuteState(state)
-- Executes a provided state in a virtual machine.
-- @param <LuaState> state The state of a Lua script.
function API.VirtualMachine.ExecuteState(state)
  local newVirtualMachine = VirtualMachine:new(state)
  newVirtualMachine:run()
end

--- API.VirtualMachine.ExecuteScript(script)
-- Executes a provided script in a virtual machine.
-- @param <String> script A Lua script.
function API.VirtualMachine.ExecuteScript(script)
  local luaState = API.Interpreter.ConvertToInstructions(script)
  API.VirtualMachine.ExecuteState(luaState)
end


---------- API.Interpreter ----------

--- API.Interpreter.ConvertToTokens(script)
-- Tokenizes a Lua script and returns its tokens.
-- @param <String> script A Lua script.
-- @return <Table> tokens The tokens of the Lua script.
function API.Interpreter.ConvertToTokens(script)
  local tokens = Lexer:new(script):tokenize()
  return tokens
end

--- API.Interpreter.ConvertToAST(script)
-- Tokenizes and parses Lua script and returns its Abstract Syntax Tree.
-- @param <String> script A Lua script.
-- @return <Table> AST The Abstract Syntax Tree of the Lua script.
function API.Interpreter.ConvertToAST(script)
  local tokens = API.Interpreter.ConvertToTokens(script)
  local AST = Parser:new(tokens):parse()
  return AST
end

--- API.Interpreter.ConvertToInstructions(script)
-- Tokenizes, parses, and converts Lua script to instructions and returns its state.
-- @param <String> script A Lua script.
-- @return <LuaState> state The state of a Lua script.
function API.Interpreter.ConvertToInstructions(script)
  local AST = API.Interpreter.ConvertToAST(script)
  local state = InstructionGenerator:new(AST):run()
  return state
end


---------- API.Assembler ----------

--- API.Assembler.Tokenize(code)
-- Tokenizes code and returns its tokens.
-- @param <String> code Assembly code.
-- @return <Table> tokens The tokens of an assembly code.
function API.Assembler.Tokenize(code)
  local tokens = Assembler:tokenize(code)
  return tokens
end

--- API.Assembler.Parse(code)
-- Tokenizes and Parses code and returns its state.
-- @param <String> code Assembly code.
-- @return <LuaState> state The state of the code.
function API.Assembler.Parse(code)
  local tokens = Assembler:tokenize(code)
  local state = Assembler:parse(tokens)
  return state
end


---------- API.MathParser ----------

--- API.MathParser.Tokenize(expression)
-- Tokenizes an expressions and returns its tokens.
-- @param <String> expression An expression.
-- @return <Table> tokens The tokens of an expression.
function API.MathParser.Tokenize(expression)
  local tokens = MathParser:tokenize(expression)
  return tokens
end

--- API.MathParser.Parse(expression)
-- Tokenizes, and parses an expressions and returns its Abstract Syntax Tree.
-- @param <String> expression An expression.
-- @return <Table> AST The Abstract Syntax Tree of an expression.
function API.MathParser.Parse(expression)
  local tokens = API.MathParser.Tokenize(expression)
  local AST = MathParser:parse(tokens)
  return AST
end

--- API.MathParser.Evaluate(expression)
-- Tokenizes, parses, and evaluates an expressions and returns its result.
-- @param <String> expression An expression.
-- @return <Any> result The result of the expression.
function API.MathParser.Evaluate(expression)
  local AST = API.MathParser.Parse(expression)
  local result = MathParser:evaluate(AST)
  return result
end


---------- API.ASTExecutor ----------

--- API.ASTExecutor.Execute(AST)
-- Execute an Abstract Syntax Tree and return its returned values.
-- @param <Table> AST An Abstract Syntax Tree of a Lua script.
-- @return <...Any> returnValue The return value of the Lua script.
function API.ASTExecutor.Execute(AST)
  local returnValues = { ASTExecutor:new(AST):execute() }
  return unpack(returnValues)
end


---------- API.Beautifier ----------

--- API.Beautifier.Beautify(script)
-- Beautify a Lua script.
-- @param <String> script A Lua script.
-- @return <String> beautifiedScript The beautified version of the given Lua script.
function API.Beautifier.Beautify(script)
  local AST = API.Interpreter.ConvertToAST(script)
  local beautifiedScript = Beautifier:new(AST):run()
  return beautifiedScript
end


---------- API.Minifier ----------

--- API.Minifier.Minify(script)
-- Minify a Lua script.
-- @param <String> script A Lua script.
-- @return <String> minifiedScript The minified version of the given Lua script.
function API.Minifier.Minify(script)
  local AST = API.Interpreter.ConvertToAST(script)
  local minifiedScript = Minifier:new(AST):run()
  return minifiedScript
end


---------- API.ASTToTokensConverter ----------

--- API.ASTToTokensConverter.ConvertToTokens(AST)
-- Minify a Lua script.
-- @param <Table> AST An Abstract Syntax Tree of a Lua script.
-- @return <Table> tokens The tokens of the given Abstract Syntax Tree.
function API.ASTToTokensConverter.ConvertToTokens(AST)
  local tokens = ASTToTokensConverter:new(AST):run()
  return tokens
end


---------- API.LuaState ----------

--- API.LuaState.NewLuaState()
-- Create a new LuaState object.
-- @return <LuaState> luaState The LuaState object.
function API.LuaState.NewLuaState()
  local luaState = LuaState:new()
  return luaState
end


---------- API.ASTHierarchy ----------

--- API.ASTHierarchy.ConvertAST(AST)
-- Convert the given Abstract Syntax Tree to ASTHierarchy object and return it
-- @param <Table> AST The Abstract Syntax Tree of a Lua script
-- @return <ASTHierarchy> astHierarchy The ASTHierarchy object of the Abstract Syntax Tree.
function API.ASTHierarchy.ConvertAST(AST)
  local astHierarchy = ASTHierarchy:new(AST):convert()
  return astHierarchy
end


---------- API.Optimizer.ASTOptimizer ----------

--- API.Optimizer.ASTOptimizer.OptimizeScript(script)
-- Convert the given script to an AST, optimize and return it
-- @param <String> script The Lua script to optimize
-- @return <Table> optimizedAST The optimized Abstract Syntax Tree.
function API.Optimizer.ASTOptimizer.OptimizeScript(script)
  local AST = API.Interpreter.ConvertToAST(script)
  local astHierarchy = API.ASTHierarchy.ConvertAST(AST)
  local optimizedAST = ASTOptimizer:new(astHierarchy):run()
  return optimizedAST
end

--- API.Optimizer.ASTOptimizer.OptimizeASTHierarchy(astHierarchy)
-- Convert the given ASTHierarchy object to an optimized AST and return it
-- @param <ASTHierarchy> astHierarchy The ASTHierarchy object
-- @return <ASTHierarchy> optimizedAST The optimized Abstract Syntax Tree.
function API.Optimizer.ASTOptimizer.OptimizeASTHierarchy(astHierarchy)
  local optimizedAST = ASTOptimizer:new(astHierarchy):run()
  return optimizedAST
end


return API