--[[
  Name: Tokenizer2.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Tokenizer/Tokenizer2")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")

--* Imports *--
local StringToTable = Helpers.StringToTable
local Class = Helpers.NewClass
local Find = Helpers.TableFind
local insert = table.insert
local concat = table.concat

--* Tokenizer *--
local Tokenizer = Class{
  __super__ = ParserBuilder;
  __init__ = function(self, string)
    self.__super__(string)
  end;

  skipOptionalWhitespaces = function(self)
    if self:isBlank(self.curChar) then
      self:readBlank(); self:consume()
    end
  end;

  isCodeBlock = function(self, character)
    return character == "{" or character == "("
  end;
  isComment = function(self, character)
    return character == "#"
  end;
  isArrow = function(self, character)
    return character == "-" and self:peek() == ">"
  end;
  isString = function(self, character)
    return character == "'" or character == '"'
  end;
  isMacro = function(self, character)
    return character == "@"
  end;
  isToken = function(self, character)
    return character == "<"
  end;

  readKeyword = function(self)
    -- Use table.concat instead of multiple string
    -- concatinations to make it faster.
    local keyword = {}
    repeat
      insert(keyword, self.CurChar)
    until not ( self:isKeyword(self:peek()) and self:consume() )

    return concat(keyword)
  end;

  readBlank = function(self)
    repeat -- Nothing
    until not ( self:isBlank(self:peek()) and self:consume() )
  end;

  readComment = function(self)
    repeat -- Nothing
    until not ( self:peek() ~= "\n" and self:consume() )
  end;

  readArrow = function(self)
    self:consume(2)
    self:skipOptionalWhitespaces()

    return self:readKeyword()
  end;
  
  readString = function(self)
    local openingQuote = self.curChar

    local string = {}
    while self:consume() ~= openingQuote and self.curChar do
      insert(string, self.curChar)
    end;
    assert(self.curChar, "Non-terminated string.")
    
    return concat(String)
  end;

  ReadMacro = function(self)
    self:consume()

    local Name = self:readKeyword()
    self:consume()
    self:skipOptionalWhitespaces()
    
    local value = {}
    if self:isCodeBlock(self.curChar) then
        self:consume()
        local myStopChars = {(self.curChar == "(" and ")" or "}")}
        Value = {{
            TYPE = "CodeBlock",
            Value = self:readCodeBlock(myStopChars)
        }}
    elseif self:IsKeyword(self.CurChar) then
        local NewKeyword = self:ReadKeyword()
        Value = {{
            TYPE = "Keyword",
            Value = NewKeyword
        }}
    elseif self:IsString(self.CurChar) then
        local NewString = self:ReadString()
        Value = {{
            TYPE = "Keyword",
            Value = NewString
        }}
    else
        repeat Insert(Value, self.CurChar)
        until not (self:Check() ~= "\n" and self:Peek())
        
        Value = {{
            TYPE = "Keyword",
            Value = Concat(Value)
        }}
    end

    return Name, Value
  end;
    ReadToken = function(self)
        self:Peek()
        
        local Params = {}
        
        local GetNextParam;
        function GetNextParam()
            if self:IsBlank(self.CurChar) then
                self:ReadBlank(); self:Peek()
            end

            local CurrentParam;
            if self:IsKeyword(self.CurChar) then
                CurrentParam = self:ReadKeyword()
            elseif self.CurChar == "%" then
                self:Peek()
                CurrentParam = "%" .. self:ReadKeyword()
            elseif self.CurChar == ">" then
                return Params
            end

            self:Peek()
            Insert(Params, CurrentParam)
            
            return GetNextParam()
        end

        return GetNextParam()
    end;
    ReadCodeBlock = function(self, StopChars)
        local AST = {}

        repeat
            if StopChars and Find(StopChars, self.CurChar) then
                return AST
            elseif self:IsBlank(self.CurChar) then
                self:ReadBlank()
            elseif self:IsComment(self.CurChar) then
                self:ReadComment()
            elseif self:IsToken(self.CurChar) then
                Insert(AST, {
                    TYPE  = "Token",
                    Value = self:ReadToken()
                })
            elseif self:IsKeyword(self.CurChar) then
                Insert(AST, {
                    TYPE  = "Keyword",
                    Value = self:ReadKeyword()
                })
            elseif self:IsMacro(self.CurChar) then
                local Name, Value = self:ReadMacro()
                Insert(AST, {
                    TYPE  = "Macro",
                    Name  = Name,
                    Value = Value
                })
            elseif self:IsCodeBlock(self.CurChar) then
                local My_StopChars = {(self.CurChar == "(" and ")" or "}")}
                self:Peek()

                Insert(AST, {
                    TYPE  = "CodeBlock",
                    Value = self:ReadCodeBlock(My_StopChars)
                })
            elseif self:IsString(self.CurChar) then
                Insert(AST, {
                    TYPE  = "String",
                    Value = self:ReadString() 
                })
            elseif self:IsArrow(self.CurChar) then
                Insert(AST, {
                    TYPE  = "Arrow",
                    Value = self:ReadArrow()
                })
            elseif self.CurChar == "}" or self.CurChar == ")" then
                return error("Unexpected end of code block")
            else
                Insert(AST, {
                    TYPE  = "Character",
                    Value = self.CurChar
                })
            end
        until not (self:Peek())
        
        return AST
    end;
    
    Tokenize = function(self)
        return self:ReadCodeBlock()
    end
}

return Tokenizer