--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Parser/Parser")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local StatementParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/StatementParser")
local NodeFactory = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/NodeFactory")
-- local LuaMathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/LuaMathParser")
local LuaMathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/LuaMathParser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local insert = table.insert

local createIdentifierNode = NodeFactory.createIdentifierNode

--* Constants *--
local STOP_PARSING_VALUE = -1

--* ParserMethods *--
local ParserMethods = {}

function ParserMethods:peek(n)
  -- Place "EOF" just in case so the script wouldn't error on an
  -- unexpected end of tokens, instead it will output the native error function
  return self.tokens[self.currentTokenIndex + (n or 1)]  or { TYPE = "EOF" }
end

function ParserMethods:consume(n)
  self.currentTokenIndex = self.currentTokenIndex + (n or 1)
  self.currentToken = self.tokens[self.currentTokenIndex] or { TYPE = "EOF" }
  return self.currentToken
end

function ParserMethods:compareTokenValueAndType(token, type, value)
  return token and (not type or type == token.TYPE) and (not value or value == token.Value)
end

function ParserMethods:tokenIsOneOf(token, tokenPairs)
  local token = token or self.currentToken
  for _, pair in ipairs(tokenPairs) do
    if self:compareTokenValueAndType(token, pair[1], pair[2]) then return true end
  end
  return false
end

function ParserMethods:isClosingParenthesis(token)
  return token.TYPE == "Character" and token.Value == ")"
end

function ParserMethods:expectCurrentToken(tokenType, tokenValue)
  local currentToken = self.currentToken
  if self:compareTokenValueAndType(currentToken, tokenType, tokenValue) then
    return currentToken
  end

  return error(("Token mismatch, expected: { TYPE: %s, Value: %s }, got: { TYPE: %s, Value: %s }"):format(
    tostring(tokenType), tostring(tokenValue), tostring(currentToken.TYPE), tostring(currentToken.Value)
  ))
end

function ParserMethods:expectNextToken(tokenType, tokenValue)
  self:consume()
  return self:expectCurrentToken(tokenType, tokenValue)
end

function ParserMethods:expectCurrentTokenAndConsume(tokenType, tokenValue)
  self:expectCurrentToken(tokenType, tokenValue)
  return self:consume()
end

function ParserMethods:expectNextTokenAndConsume(tokenType, tokenValue)
  self:expectNextToken(tokenType, tokenValue)
  return self:consume()
end

function ParserMethods:isTable()
  local token = self.currentToken
  return token and token.TYPE == "Character" and token.TYPE == "{"
end;

function ParserMethods:addSelfToArguments(arguments)
  local newArguments = { createIdentifierNode("self") }
  for index, value in ipairs(arguments) do
    newArguments[index + 1] = value
  end
  return newArguments
end

function ParserMethods:identifiersToValues(identifiers)
  local values = {}
  for _, identifierNode in ipairs(identifiers) do
    insert(values, identifierNode.Value)
  end
  return values
end

function ParserMethods:consumeExpression(errorOnFail)
  local expression = LuaMathParser:getExpression(self, self.tokens, self.currentTokenIndex, errorOnFail)
  return expression
end

function ParserMethods:consumeMultipleExpressions(maxAmount)
  local expressions = { self:consumeExpression(false) }

  if #expressions == 0 then return expressions end
  if self:compareTokenValueAndType(self:peek(), "Character", ",") then
    while self:compareTokenValueAndType(self:peek(), "Character", ",") do
      if maxAmount and #expressions >= maxAmount then break end
      self:consume() -- Consume the last token of the last expression
      self:consume() -- Consume ","
      insert(expressions, self:consumeExpression(false))
    end
  end

  return expressions
end

function ParserMethods:consumeMultipleIdentifiers(oneOrMore)
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

function ParserMethods:areValidCodeBlockExpressions(expressions)
  if not expressions then return end
  if not expressions[1] then return end

  if #expressions == 1 then
    if expressions[1].Value.TYPE == "FunctionCall" then return true
    elseif expressions[1].Value.TYPE == "MethodCall" then return true end
  end

  for _, value in ipairs(expressions) do
    if value.Value.TYPE == "Identifier" or value.Value.TYPE == "Index" then
    else return false end
  end
  return true
end

function ParserMethods:getNextNode(stopKeywords)
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
  elseif type == "EOF" then
    return STOP_PARSING_VALUE
  else
    local codeBlockExpressions = self:consumeMultipleExpressions()
    if not self:areValidCodeBlockExpressions(codeBlockExpressions) then
      Helpers.PrintTable(self.tokens)
      print(self.currentTokenIndex)
      return error(("Unexpected node: %s (Perhaps you forgot to place a ';' there?)"):format(stringifyTable(codeBlockExpressions)))
    end

    if codeBlockExpressions[1].Value.TYPE == "FunctionCall" or codeBlockExpressions[1].Value.TYPE == "MethodCall" then
      returnValue = codeBlockExpressions[1].Value
    else
      self:consume() -- Consume the last variable token
      returnValue = self:__VariableAssignment(codeBlockExpressions)
    end
  end

  -- Consume an optional semicolon
  if self:compareTokenValueAndType(self:peek(), "Character", ";") then
    self:consume()
  end
  return returnValue
end

function ParserMethods:consumeCodeBlock(stopKeywords)
  local ast = {}
  while self.currentToken do
    local newAST = self:getNextNode(stopKeywords)
    if not newAST then error(("Unexpected token: %s"):format(stringifyTable(currentToken)))
    elseif newAST == STOP_PARSING_VALUE then break end

    insert(ast, newAST)
    self:consume()
  end
  return ast
end

-- Main method (public)
function ParserMethods:parse()
  local returnValue = self:consumeCodeBlock()
  return returnValue
end

--* Parser *--
local Parser = {}
function Parser:new(tokens)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.currentToken = tokens[1]
  ParserInstance.currentTokenIndex = 1

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ParserInstance: " .. index)
      end
      ParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("ParserMethods", ParserMethods)

  -- Other
  inheritModule("StatementParser", StatementParser)
  -- inheritModule("LuaMathParser", LuaMathParser:new())

  return ParserInstance
end

return Parser