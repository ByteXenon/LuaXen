--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/Parser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local KeywordsParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/KeywordsParser")
local LuaMathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/LuaMathParser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

--* Parser *--
local Parser = {}
function Parser:new(tokens)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.currentToken = tokens[1]
  ParserInstance.currentTokenIndex = 1

  for index, func in pairs(KeywordsParser) do
    ParserInstance[index] = func
  end

  function ParserInstance:peek(n)
    return self.tokens[self.currentTokenIndex + (n or 1)]
  end
  function ParserInstance:consume(n)
    self.currentTokenIndex = self.currentTokenIndex + (n or 1)
    self.currentToken = self.tokens[self.currentTokenIndex]
    return self.currentToken
  end

  function ParserInstance:compareTokenValueAndType(token, type, value)
    return token and (not type or type == token.TYPE) and (not value or value == token.Value)
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

  function ParserInstance:handleTokenWithFunction(tokenCases)
    local currentToken = self.currentToken
    for _, case in ipairs(tokenCases) do
      local tokenCase = case.token
      if self:compareTokenValueAndType(currentToken, tokenCase.TYPE, tokenCase.Value) then
        return case.func(self)
      end
    end

    return error("Unexpected token: " .. currentToken.Value)
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

  function ParserInstance:createOperatorNode(operatorValue, leftExpr, rightExpr, operand)
    return { TYPE = "Operator", Value = operatorValue, Left = leftExpr, Right = rightExpr, Operand = operand }
  end
  function ParserInstance:createFunctionCallNode(expression, arguments)
    return { TYPE = "FunctionCall", Expression = expression, Arguments = arguments }
  end
  function ParserInstance:createNumberNode(value)
    return { TYPE = "Number", Value = value }
  end
  function ParserInstance:createIndexNode(index, value)
    return { TYPE = "Index", Index = index, Value = value }
  end
  function ParserInstance:createTableNode(values)
    return { TYPE = "Table", Values = values }
  end
  function ParserInstance:createFunctionNode(arguments, codeBlock)
    return { TYPE = "Function", Arguments = arguments, CodeBlock = codeBlock }
  end
  
  function ParserInstance:consumeExpression(errorOnFail)
    local expression = LuaMathParser:getExpression(self, self.tokens, self.currentTokenIndex, errorOnFail)
    return expression
  end

  function ParserInstance:consumeMultipleExpressions()
    local expressions = {
      self:consumeExpression(false)
    }
    if #expressions == 0 then return expressions end
    while self:compareTokenValueAndType(self:peek(), "Character", ",") and self:consume(2) do
      local expression = self:consumeExpression()
      insert(expressions, expression)
    end
    return expressions
  end

  function ParserInstance:consumeMultipleIdentifiers(oneOrMore)
    local identifiers = {}
    if oneOrMore then
      self:expectCurrentToken("Identifier")
    end

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

  -- function(<args>) <code_block> end
  function ParserInstance:consumeFunction()
    self:consume() -- Consume the "function" keyword
    self:expectCurrentToken("Character", "(")
    self:consume() -- Consume "("
    local arguments = self:consumeMultipleIdentifiers()
    self:expectCurrentToken("Character", ")")
    self:consume() -- Consume ")"
    local codeBlock = self:consumeCodeBlock({ "end" })
    self:expectCurrentToken("Keyword", "end")
    self:consume()
    return self:createFunctionNode(arguments, codeBlock)
  end
  -- <table>.<index>
  function ParserInstance:consumeTableIndex(currentExpression)
    self:consume() -- Consume the "." symbol
    local currentToken = self.currentToken
    --assert(currentToken.TYPE == "Identifier", "Invalid expression")
    self:consume()
    if currentToken.TYPE == "Identifier" then
      return self:createIndexNode({ TYPE = "String", Value = currentToken.Value }, currentExpression)
    end
    return self:createIndexNode(currentToken, currentExpression)
  end

  -- <table>:<method_name>(<args>*)
  function ParserInstance:consumeMethodCall(currentExpression)
    self:consume() -- Consume the ":" symbol
    local functionName = self.currentToken
    if functionName.TYPE ~= "Identifier" then
      return error("Incorrect function name")
    end
    self:consume() -- Consume the function name
    local functionCall = self:consumeFunctionCall(self:createIndexNode(functionName.Value, currentExpression))

    return self:createFunctionCallNode(functionCall.Expression, self:addSelfToArguments(functionCall.Arguments))
  end

  -- <function_name>(<args>*)
  function ParserInstance:consumeFunctionCall(currentExpression)
    self:consume() -- Consume the "(" symbol
    
    -- Get arguments for the function
    local arguments = {};
    if not self:isClosingParenthesis(self.currentToken) then
      arguments = self:consumeMultipleExpressions()
    end

    self:consume()
    return self:createFunctionCallNode(currentExpression, arguments)
  end
  
  -- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , )? }*
  function ParserInstance:consumeTable()
    self:consume() -- Consume "{"
    
    local elements = {}
    local index = 1
    while not self:compareTokenValueAndType(self.currentToken, "Character", "}") do
      local curToken = self.currentToken
      if self:compareTokenValueAndType(curToken, "Character", "[") then
        self:consume() -- Consume "["
        local key = self:consumeExpression()
        self:expectNextToken("Character", "]")
        self:expectNextToken("Character", "=")
        self:consume() -- Consume "="
        local value = self:consumeExpression()
        insert(elements, { key, value })
      elseif curToken.TYPE == "Identifier" then
        local key =  curToken.Value
        self:expectNextToken("Character", "=")
        self:consume() -- Consume "="
        local value = self:consumeExpression()
        insert(elements, { key, value })
      else
        local value = self:consumeExpression()
        insert(elements, { self:createNumberNode(index), value })
        index = index + 1
      end
      self:consume() -- Consume the last token of the expression

      if self:compareTokenValueAndType(self.currentToken, "Character", ",") then
        self:consume()
      else
        -- Break the loop, it will error if this is not the true end anyway.
        break
      end
    end

    self:consume() -- Consume "}"
    return self:createTableNode(elements) 
  end

  function ParserInstance:handleSpecialOperators(token, leftExpr)
    if token.TYPE == "Character" then
      -- <table>.<index>
      if token.Value == "." then return self:consumeTableIndex(leftExpr)
      -- <table>:<method_name>(<args>*)
      elseif token.Value == ":" then return self:consumeMethodCall(leftExpr)
      -- <function_name>(<args>*)
      elseif token.Value == "(" then return self:consumeFunctionCall(leftExpr) end
    end
  end
  function ParserInstance:handleSpecialOperands(token)
    if token.TYPE == "Character" then
       -- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , )? }*
      if token.Value == "{" then return self:consumeTable() end
    elseif token.TYPE == "Keyword" then
      -- function(<args>) <code_block> end
      if token.Value == "function" then return self:consumeFunction() end
    end
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
        return -1
      end

      local keywordFunction = self["_" .. value]
      if not keywordFunction then
        error("Unsupported keyword on Lua Parser side [You're not supposed to see this error]")
      end
      returnValue = keywordFunction(self)
    elseif type == "Identifier" and self:compareTokenValueAndType(self:peek(), "Character", ",") or self:compareTokenValueAndType(self:peek(), "Character", "=") then
      local variables = {}
      repeat
        insert(variables, self:expectCurrentToken("Identifier"))
        self:consume()
      until not (self:compareTokenValueAndType(self.currentToken, "Character", ",") and self:consume())
      self:expectCurrentToken("Character", "=")
      self:consume()
      returnValue = {
        Expressions = self:consumeMultipleExpressions(),
        Variables = variables,
        TYPE = "VariableAssignment"
      }
    elseif type == "EOF" then
      return -1
    else
      local codeBlockExpression = self:consumeExpression()
      
      if not self:isValidCodeBlockExpression(codeBlockExpression) then
        return error(("Unexpected token: %s"):format(stringifyTable(currentToken)))  
      end
      returnValue = codeBlockExpression
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
      if newAST then
        if newAST == -1 then break end
        insert(ast, newAST)
      end
      self:consume()
    end

    return ast
  end
  function ParserInstance:parse()
    return self:consumeCodeBlock()
  end
  
  return ParserInstance
end

return Parser