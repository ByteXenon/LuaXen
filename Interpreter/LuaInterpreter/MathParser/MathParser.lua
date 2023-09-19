--[[
  Name: MathParser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/MathParser/MathParser")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")

local Evaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Evaluator/Evaluator")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Parser/Parser")

--* Export library functions *--
local Class = Helpers.NewClass

-- * MathParser * --
local MathParser = {}
function MathParser:new(operatorPrecedences, operatorFunctions)
  local MathParserInstance = {}

  MathParserInstance.operatorPrecedences = operatorPrecedences
  MathParserInstance.operatorFunctions = operatorFunctions

  function MathParserInstance:tokenize(expression)
    local lexer = Lexer:new(expression)
    local tokens = lexer:run()
    return tokens
  end;
  function MathParserInstance:parse(tokens)
    local parser = Parser:new(tokens, self.operatorPrecedences)
    local AST = parser:parse()
    return AST
  end;
  function MathParserInstance:evaluate(AST)
    local evaluator = Evaluator:new(AST, self.operatorFunctions)
    local result = evaluator:evaluate()
    return result
  end;
  function MathParserInstance:solve(expression)
    return self:evaluate(self:parse(self:tokenize(expression)))
  end;

  return MathParserInstance
end

return MathParser