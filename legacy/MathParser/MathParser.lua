--[[
  Name: MathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-04-25
--]]

--* Dependencies *--


local Evaluator = require("Interpreter/LuaInterpreter/MathParser/Evaluator/Evaluator")
local Lexer = require("Interpreter/LuaInterpreter/MathParser/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/MathParser/Parser/Parser")

--* MathParserMethods *--
local MathParserMethods = {}

--- Tokenizes the given expression.
-- @param <String> expression The expression to tokenize.
-- @return <Table> tokens The tokens of the expression.
function MathParserMethods:tokenize(expression)
  self.Lexer:resetToInitialState(expression, self.operators)
  local tokens = self.Lexer:run()
  return tokens
end

--- Parses the given tokens.
-- @param <Table> tokens The tokens to parse.
-- @return <Table> AST The AST of the tokens.
function MathParserMethods:parse(tokens)
  self.Parser:resetToInitialState(tokens, self.operatorPrecedences)
  local AST = self.Parser:parse()
  return AST
end

--- Evaluates the given AST.
-- @param <Table> AST The AST to evaluate.
-- @return <Number> evaluatedValue The result of the evaluation.
function MathParserMethods:evaluate(AST)
  self.Evaluator:resetToInitialState(AST, self.variables, self.operatorFunctions, self.functions)
  local evaluatedValue = self.Evaluator:evaluate()
  return evaluatedValue
end

--- Solves the given expression.
-- @param <String> expression The expression to solve.
-- @return <Number> result The result of the expression.
function MathParserMethods:solve(expression)
  return self:evaluate(self:parse(self:tokenize(expression)))
end

--- Adds a variable to its value.
-- @param <String> variableName The name of the variable.
-- @param <Number> variableValue The value of the variable.
function MathParserMethods:addVariable(variableName, variableValue)
  self.variables = self.variables or {}
  self.variables[variableName] = variableValue
end

--- Adds multiple variables to their values.
-- @param <Table> variables The variables to add.
function MathParserMethods:addVariables(variables)
  for variableName, variableValue in pairs(variables) do
    self:addVariable(variableName, variableValue)
  end
end

--- Adds a function to the evaluator.
-- @param <String> functionName The name of the function.
-- @param <Function> functionValue The function to add.
function MathParserMethods:addFunction(functionName, functionValue)
  self.functions = self.functions or {}
  self.functions[functionName] = functionValue
end

--- Adds multiple functions to the evaluator.
-- @param <Table> functions The functions to add.
function MathParserMethods:addFunctions(functions)
  for functionName, functionValue in pairs(functions) do
    self:addFunction(functionName, functionValue)
  end
end

--* MathParser *--
local MathParser = {}

--- @class Creates a new MathParser.
-- @param <Table> operatorPrecedences The operator precedences to use in the parser.
-- @param <Table> variables The variables to use in the evaluator.
-- @param <Table> operatorFunctions The operator functions to evaluate in the evaluator.
-- @param <Table> functions The functions to use in the evaluator
-- @return <Table> MathParserInstance The MathParser instance.
function MathParser:new(operatorPrecedences, variables, operatorFunctions, functions)
  local MathParserInstance = {}

  -- Properties
  MathParserInstance.operatorPrecedences = operatorPrecedences
  MathParserInstance.variables = variables
  MathParserInstance.operatorFunctions = operatorFunctions
  MathParserInstance.functions = functions

  -- Classes
  MathParserInstance.Lexer = Lexer:new(nil)
  MathParserInstance.Parser = Parser:new(nil, operatorPrecedences)
  MathParserInstance.Evaluator = Evaluator:new(nil, variables, operatorFunctions, functions)

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if MathParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and MathParserInstance: " .. index)
      end
      MathParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("MathParserMethods", MathParserMethods)

  return MathParserInstance
end

return MathParser