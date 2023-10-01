--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/Parser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local StatementParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/StatementParser")
local LuaMathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/LuaMathParser")
local Debugger = ModuleManager:loadModule("Debugger/Debugger")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

local STOP_PARSING_VALUE = -1

--* Parser *--
local Parser = {}
function Parser:new(tokens)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.currentToken = tokens[1]
  ParserInstance.currentTokenIndex = 1

  for _, tb in ipairs({StatementParser}) do
    for index, func in pairs(tb) do
      ParserInstance[index] = func
    end
  end

  function ParserInstance:peek(n)
    -- Place "EOF" just in case so the script wouldn't error on an 
    -- unexpected end of tokens, instead it will output the native error function
    return self.tokens[self.currentTokenIndex + (n or 1)]  or { TYPE = "EOF" }
  end
  function ParserInstance:consume(n)
    self.currentTokenIndex = self.currentTokenIndex + (n or 1)
    self.currentToken = self.tokens[self.currentTokenIndex] or { TYPE = "EOF" }
    return self.currentToken
  end

  function ParserInstance:compareTokenValueAndType(token, type, value)
    return token and (not type or type == token.TYPE) and (not value or value == token.Value)
  end

  function ParserInstance:tokenIsOneOf(token, tokenPairs)
    local token = token or self.currentToken
    for _, pair in ipairs(tokenPairs) do
      if self:compareTokenValueAndType(token, pair[1], pair[2]) then return true end
    end
    return false
  end 

  function ParserInstance:isClosingParenthesis(token)
    return token.TYPE == "Character" and token.Value == ")"
  end

  function ParserInstance:expectCurrentToken(tokenType, tokenValue)
    local currentToken = self.currentToken
    if self:compareTokenValueAndType(currentToken, tokenType, tokenValue) then
      return currentToken
    end

    return error(("Token mismatch, expected: { TYPE: %s, Value: %s }, got: { TYPE: %s, Value: %s }"):format(
      tostring(tokenType), tostring(tokenValue), tostring(currentToken.TYPE), tostring(currentToken.Value)
    ))
  end
  function ParserInstance:expectNextToken(tokenType, tokenValue)
    self:consume()
    return self:expectCurrentToken(tokenType, tokenValue)
  end

  function ParserInstance:expectCurrentTokenAndConsume(tokenType, tokenValue)
    self:expectCurrentToken(tokenType, tokenValue)
    return self:consume()
  end
  function ParserInstance:expectNextTokenAndConsume(tokenType, tokenValue)
    self:expectNextToken(tokenType, tokenValue)
    return self:consume()
  end 
  
  function ParserInstance:isTable()
    local token = self.currentToken
    return token and token.TYPE == "Character" and token.TYPE == "{"
  end;

  function ParserInstance:addSelfToArguments(arguments)
    local newArguments = { { TYPE = "Identifier", Value = "self" } }
    for index, value in ipairs(arguments) do
      newArguments[index + 1] = value
    end
    return newArguments
  end

  
  function ParserInstance:createOperatorNode(operatorValue, leftExpr, rightExpr, precedence)
    return { TYPE = "Operator", Value = operatorValue, Left = leftExpr, Right = rightExpr, Precedence = precedence }
  end
  function ParserInstance:createUnaryOperatorNode(operatorValue, operand, precedence)
    return { TYPE = "UnaryOperator", Value = operatorValue, Operand = operand, Precedence = precedence }
  end
  function ParserInstance:createFunctionCallNode(expression, parameters)
    return { TYPE = "FunctionCall", Expression = expression, Parameters = parameters }
  end
  function ParserInstance:createIdentifierNode(value)
    return { TYPE = "Identifier", Value = value }
  end
  function ParserInstance:createNumberNode(value)
    return { TYPE = "Number", Value = value }
  end
  function ParserInstance:createIndexNode(index, expression)
    return { TYPE = "Index", Index = index, Expression = expression }
  end
  function ParserInstance:createTableNode(elements)
    return { TYPE = "Table", Elements = elements }
  end
  function ParserInstance:createTableElementNode(key, value)
    return { TYPE = "TableElement", Key = key, Value = value }
  end
  function ParserInstance:createFunctionNode(parameters, codeBlock, fields)
    return { TYPE = "Function", Parameters = parameters, CodeBlock = codeBlock, Fields = fields }
  end

  function ParserInstance:identifiersToValues(identifiers)
    local values = {}
    for _, identifierNode in ipairs(identifiers) do
      insert(values, identifierNode.Value)
    end
    return values
  end
  function ParserInstance:consumeExpression(errorOnFail)
    local expression = LuaMathParser:getExpression(self, self.tokens, self.currentTokenIndex, errorOnFail)
    return expression
  end
  function ParserInstance:consumeMultipleExpressions(maxAmount)
    local expressions = { self:consumeExpression(false) }

    if #expressions == 0 then return expressions end
    if self:compareTokenValueAndType(self:peek(), "Character", ",") then
      while self:compareTokenValueAndType(self:peek(), "Character", ",") do 
        if maxAmount and #expressions >= maxAmount then break end
        self:consume() -- Consume the last token of the last expression
        self:consume() -- Consume ","
        --print("------------------")
        insert(expressions, self:consumeExpression(false))
        --Helpers.PrintTable(expressions)
        --Helpers.PrintTable(self.currentToken)
        --print("------------------")
      end
    end
    -- self:consume()
    
    return expressions
  end
  function ParserInstance:consumeMultipleIdentifiers(oneOrMore)
    local identifiers = {}
    if oneOrMore then self:expectCurrentToken("Identifier") end
  
    while self:compareTokenValueAndType(self.currentToken, "Identifier") do
      local identifier = self.currentToken
      insert(identifiers, identifier)
      if not self:compareTokenValueAndType(self:consume(), "Character", ",") then
        break
      end
      self:consume()
    end
    
    return identifiers
  end
  function ParserInstance:isValidCodeBlockExpression(expression)
    return expression["TYPE"] == "FunctionCall" 
  end

  function ParserInstance:getNextAST(stopKeywords)
    local currentToken = self.currentToken
    local value, type = currentToken.Value, currentToken.TYPE
    
    local returnValue;
    if type == "Keyword" then
      if stopKeywords and find(stopKeywords, value) then
        return STOP_PARSING_VALUE
      end

      local keywordFunction = self["_" .. value]
      if not keywordFunction then
        error("Unsupported keyword on Lua Parser side: " .. value)
      end
      returnValue = keywordFunction(self)
    elseif type == "Identifier" and self:tokenIsOneOf(self:peek(), {{"Character", "."}, {"Character", ","}, {"Character", "="}}) then
      return self:__VariableAssignment()
    elseif type == "EOF" then
      return STOP_PARSING_VALUE
    else
      local codeBlockExpression = self:consumeExpression()
      
      if not self:isValidCodeBlockExpression(codeBlockExpression) then
        return error(("Unexpected token: %s (Perhaps you forgot to place a ';' there?)"):format(stringifyTable(codeBlockExpression)))
      end
      returnValue = codeBlockExpression
      -- self:consume()
    end

    -- Consume an optional semicolon
    if self:compareTokenValueAndType(self:peek(), "Character", ";") then
      self:consume()
    end
    return returnValue
  end
  function ParserInstance:consumeCodeBlock(stopKeywords)
    local ast = {}
    while self.currentToken do
      local newAST = self:getNextAST(stopKeywords)
      if not newAST then error(("Unexpected token: %s"):format(stringifyTable(currentToken)))
      elseif newAST == STOP_PARSING_VALUE then break end
      
      insert(ast, newAST)
      self:consume()
    end
    return ast
  end
  function ParserInstance:parse()
    local returnValue = self:consumeCodeBlock()
    
    return returnValue
  end
  
  return ParserInstance
end

return Parser