--[[
  Name: Interpreter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/Interpreter")

local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")
local MathEvaluator = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Evaluator/Evaluator")
local MathLexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Lexer/Lexer")
local MathParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/MathParser/Parser/Parser")

local SyntaxStatementParser = ModuleManager:loadModule("Interpreter/LuaInterpreter/SyntaxStatementParser")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local insert = table.insert
local byte = string.byte
local concat = table.concat
local char = string.char
local find = table.find or Helpers.TableFind
local rep = string.rep


local Interpreter = {}
function Interpreter:new(string)
  local InterpreterInstance = {}

  InterpreterInstance.charStream = StringToTable(string)
  InterpreterInstance.curChar = InterpreterInstance.charStream[1]
  InterpreterInstance.curCharPos = 1
  local reservedKeywords = {
    "while", "do", "end", "for", "repeat", "until", "return", "in", "if"
  }

  for i,v in pairs(ParserBuilder.__raw__) do
    InterpreterInstance[i] = v
  end


  function InterpreterInstance:isNumber()
    local curChar = self.curChar
    return curChar and curChar:match("%d")
  end;
  function InterpreterInstance:isString()
    local curChar = self.curChar;
    local nextChar = self:peek()

    return (curChar == "'" or curChar == '"') or
           (curChar == "[" and (nextChar == "[" or
           (nextChar == "=" and (self:peek() == "[" or self:peek() == "="))))
  end;
  function InterpreterInstance:isVarArg()
    return concat(self:peekRange(0, 2)) == "..."
  end;
  function InterpreterInstance:consumeVarArg()
    local str = self:peekRange(0, 2)
    self:consume(2)
    return concat(str)
  end
  function InterpreterInstance:isAnonymousFunction()
    return concat(self:peekRange(0, 7)) == "function"
  end
  function InterpreterInstance:consumeAnonymousFunction()
    self:consume(8)
    self:expectChars("(")
    local parseFields;
    local function parseFields(fields)
      if self:isWhitespace() then self:consumeWhitespace() self:consume() end
      if self:isIdentifier() then insert(fields, self:consumeIdentifier())
      elseif self:isVarArg() then insert(fields, self:consumeVarArg()) self:consume() return fields
      else error() end
      if self:isWhitespace() then self:consumeWhitespace() self:consume() end
      if self.curChar == "," then
        self:consume()
        parseFields(fields)
      end
      return fields
    end
    if self:isWhitespace() then self:consumeWhitespace() self:consume() end
    local fields = {}
    
    if self.curChar ~= ")" then parseFields(fields) end
    self:expectChars(")")
    local codeBlock = self:codeBlockHandler({}, {"end"})
    return {
      TYPE = "AnonymousFunction",
      Fields = fields,
      CodeBlock = codeBlock
    }
  end 
  function InterpreterInstance:isTable()
    return self.curChar == "{"
  end
  function InterpreterInstance:consumeTable()
    local elements = {}
    self:consume(1)
    while true do
      local curChar = self.curChar
      if curChar == "}" or not curChar then break end
      if self:isWhitespace() then
        self:consumeWhitespace() 
        self:consume()
      elseif self:isComment() then
        self:consumeComment()
        self:consume()
      else
        if curChar == "[" then
          self:consume()
          self:consumeOptionalWhitespace()
          
          local index = self:consumeExpression();
          self:expectChars("]")
          self:consumeOptionalWhitespace()
          self:expectChars("=")
          local value = self:consumeExpression()
          elements[index] = value
        else
          local value = self:consumeExpression()
          insert(elements, value)
        end
        self:consumeOptionalWhitespace()
        if self.curChar == "}" then break
        elseif self.curChar == "," or self.curChar == ";" then
          self:consume()
        else
          return error(self.curChar)
        end
      end
    end
  
    self:expectChars("}")
    
    return {
      TYPE = "Table",
      Elements = elements,
    }
  end

  function InterpreterInstance:consumeExpression()
    
    local myLexer = MathLexer:new(self.charStream, self.curCharPos)
    for i,v in pairs(self) do myLexer[i] = v end

    local superSelf = self
    function myLexer:consumeToken()
      local curChar = self.curChar
      local operators = {"+", "-", "*", "/", "^", "#"}
      
      if self:isWhitespace() then
      elseif curChar == ")" or curChar == "(" then
        return { TYPE = "Constant", SUBTYPE = "Parentheses", Value = curChar }
      elseif find(operators, curChar) then
        return { TYPE = "Constant", SUBTYPE = "Operator", Value = curChar }
      elseif superSelf.isAnonymousFunction(self) then
        local anonymousFunction = superSelf.consumeAnonymousFunction(self)
        return { TYPE = "Constant", SUBTYPE = "AnonymousFunction", CodeBlock = anonymousFunction.CodeBlock, Fields = anonymousFunction.Fields }
      elseif self:isIdentifier() then
        local newIdentifier = self:consumeIdentifier()
        if find(reservedKeywords, newIdentifier) then
          return
        end
        return { TYPE = "Constant", SUBTYPE = "Identifier", Value = newIdentifier }
      elseif self:isDigit() then
        return { TYPE = "Constant", SUBTYPE = "Number", Value = self:consumeNumber() }
      elseif superSelf.isString(self) then
        return { TYPE = "Constant", SUBTYPE = "String", Value = superSelf.consumeString(self) }
      elseif superSelf.isTable(self) then
        local newTable = superSelf.consumeTable(self)
        return { TYPE = "Constant", SUBTYPE = "Table", Elements = newTable.Elements }
      elseif superSelf.isVarArg(self) then
        superSelf.consumeVarArg(self)
        return { TYPE = "Constant", SUBTYPE = "VarArg" } 
      else
        return -1
      end
    end

    local tokens = myLexer:run()

    if #tokens == 0 then
      error("Invalid expression")
    end
    self.curChar = myLexer.curChar
    self.curCharPos = myLexer.curCharPos 
    return MathParser:new(tokens):parse()
  end;
  function InterpreterInstance:consumeString()
    local function ConsumeSimpleString()
      local startQuote = self:expectChars('"', "'")

      local NewString = self:readWhile(nil, function()
        local curChar = self.curChar
        if curChar == startQuote then
          return false -- Stop recording stuff
        elseif curChar == "\\" then
          local nextChar = self:consume()
          if self:isDigit() then
            return char(tonumber(self:consumeDigit()))
          else
            return nextChar
          end
        end

        return curChar
      end)

      return NewString
    end;
    local function ConsumeComplexString()
      self:expectChars("[")
      local depth = #self:readWhileChar("=")
      self:expectChars("[")
      
      local closingString = "]" .. rep("=", depth) .. "]"
      return self:readWhileNotString(closingString)
    end;

    local nextChar = self:peek();
    if self.curChar == "'" or self.curChar == '"' then
      return ConsumeSimpleString()
    elseif self.curChar == "[" and (nextChar == "=" or nextChar == "[") then
      return ConsumeComplexString()
    end;

    return error("Invalid type of string")
  end;
  function InterpreterInstance:isComment()
    return self.curChar == "-" and self:peek() == "-"
  end;
  function InterpreterInstance:consumeComment()
    self:expectChars("-")
    self:expectChars("-")

    local curChar = self.curChar;
    local nextChar = self:peek()
    if curChar == '[' and (nextChar == '[' or nextChar == "=") then
      return self:consumeString()
    else
      return self:readWhileNotString("\n")
    end;
  end;
  function InterpreterInstance:consumeCodeBlock(stopKeywords)
    local curChar = self.curChar
    if self:isIdentifier() then
      local curIdentifier = self:consumeIdentifier()
      if find(stopKeywords or {}, curIdentifier) then
        return
      elseif find(reservedKeywords, curIdentifier) then
        return SyntaxStatementParser:new(self):consume(curIdentifier)
      end
      return {
        TYPE = "Identifier",
        Value = curIdentifier
      }
    elseif self:isString() then
      local curString = self:consumeString()
      return {
        TYPE = "String",
        Value = curString
      }
    elseif self:isComment() then
      local curComment = self:consumeComment();
      return {
        TYPE = "Comment",
        Value = curComment
      }
    end
  end;
  function InterpreterInstance:codeBlockHandler(returnTb, stopKeywords)
    local returnTb = returnTb or {}
    while self.curChar do
      local val = self:consumeCodeBlock(stopKeywords)
      if val then insert(returnTb, val) end
      self:consume()
    end
    return returnTb
  end;

  function InterpreterInstance:interpret()
    return self:codeBlockHandler()
  end

  return InterpreterInstance
end

return Interpreter