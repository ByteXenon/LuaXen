--[[
  Name: Parser.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Assembler/Parser/")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

--* Export library functions *--
local find = Helpers.TableFind
local formattedError = Helpers.FormattedError
local insert = table.insert
local concat = table.concat

-- * Parser * --
local Parser = {};
function Parser:new(tokens)
  local ParserInstance = {
    tokens = tokens,
    tokenIndex = 1,
    curToken = tokens[1],
    state = LuaState:new(),
    labels = {}
  }

  function ParserInstance:updateCurToken()
    self.curToken = self.tokens[self.tokenIndex]
  end
  function ParserInstance:peek(n)
    return self.tokens[self.tokenIndex + (n or 1)]
  end
  function ParserInstance:consume(n)
    self.tokenIndex = self.tokenIndex + (n or 1)
    self:updateCurToken()
  end

  function ParserInstance:findOrCreateConstant(constant)
    constantIndex = find(self.state.constants, constant) 
    if not constantIndex then
      insert(self.state.constants, constant)
      constantIndex = #self.state.constants
    end
    return constantIndex
  end

  function ParserInstance:expectNextTokenType(expectedTypes, consume)
    local nextToken = (consume and (self:consume() or {})) or self:peek()
    local nextTokenType = nextToken.TYPE
    if find(expectedTypes, nextTokenType) then return true end
    return formattedError("Unexpected token type: {0}", nextTokenType)
  end

  function ParserInstance:consumeFields()
    local fields = {}
    -- Keyword is used for labels (references) and number for instructions' params
    local allowedTypes = {"KEYWORD", "NUMBER", "STRING"}

    self:consume()
    if not find(allowedTypes, self.curToken.TYPE) then return fields end 
    while true do
      local curToken = self.curToken

      -- handle labels
      if curToken.TYPE == "KEYWORD" then
        local label = self.labels[curToken.Value]
        if not label then
          formattedError("Unknown label: {0}", curToken.Value)
        end
        curToken = {
          TYPE = "NUMBER",
          Value = label.ValueLocation
        }
      elseif curToken.TYPE == "STRING" then
        curToken = {
          TYPE = "NUMBER",
          Value = -self:findOrCreateConstant(curToken.Value)
        }
      end

      insert(fields, tonumber(curToken.Value))
      if not self:peek() then break end
      if self:peek().Value == "," then self:consume() end
      if not find(allowedTypes, self:peek().TYPE) then break end

      self:consume()
    end
    return fields
  end
  function ParserInstance:consumeFunction()
    local Tokens = {}
    
    self:consume()
    while self:peek().TYPE ~= "RIGHT_BRACE" do
      local curToken = self.curToken
      if not curToken then break end

      insert(Tokens, curToken)
      self:consume()
    end
    return Tokens
  end
  function ParserInstance:getParsedToken()
    local currentToken = self.curToken
    local currentTokenType = currentToken.TYPE
    if currentTokenType == "KEYWORD" then
      if self:peek().TYPE == "COLON" then
        self:consume(2)
        local labelValueToken = ParserInstance:getParsedToken()
        local valueLocation;
        if labelValueToken.TYPE == "STRING" or labelValueToken.TYPE == "NUMBER" then
          valueLocation = -self:findOrCreateConstant(labelValueToken.Value)
        elseif labelValueToken.TYPE == "PROTO" then
          insert(self.state.protos, labelValueToken.Value)
          valueLocation = #self.state.protos
        end

        local label = {
          TYPE = "LABEL",
          Name = currentToken.Value,
          ValueLocation = valueLocation
        }
        return label
      end
      
      local instruction = {currentToken.Value, unpack(self:consumeFields())}
      self:consume()
      return {TYPE = "INSTRUCTION", Value = instruction}
    elseif currentTokenType == "STRING" then
      return {TYPE = "STRING", Value = currentToken.Value}
    elseif currentTokenType == "NUMBER" then
      return {TYPE = "NUMBER", Value = tonumber(currentToken.Value)}
    elseif currentTokenType == "LEFT_BRACE" then
      return {TYPE = "PROTO", Value = Parser:new(self:consumeFunction()):run() }
    else
      -- debug
    end
  end
  function ParserInstance:consumeNextToken()
    local parsedToken = self:getParsedToken()
    local parsedTokenType = parsedToken and parsedToken.TYPE

    if parsedTokenType == "INSTRUCTION" then
      insert(self.state.instructions, parsedToken.Value)
    elseif parsedTokenType == "LABEL" then
      self.labels[parsedToken.Name] = parsedToken
    elseif parsedTokenType == "STRING" or parsedTokenType == "NUMBER" then
      self:findOrCreateConstant(parsedToken.Value)
    else
    end
  end

  function ParserInstance:run()
    while self.curToken do
      local returnValue = self:consumeNextToken()
      self:consume()
    end

    local newConstantTable = {}
    for i,v in pairs(self.state.constants) do
      newConstantTable[-i] = v
    end
    self.state.constants = newConstantTable

    return self.state
  end

  return ParserInstance
end;

return Parser