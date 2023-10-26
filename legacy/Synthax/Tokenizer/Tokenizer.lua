--[[
  Name: Tokenizer.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Tokenizer/Tokenizer")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local ParserBuilder = ModuleManager:loadModule("Interpreter/ParserBuilder/ParserBuilder")

--* Export library functions *--
local StringToTable = Helpers.StringToTable
local Class = Helpers.NewClass
local Find = Helpers.TableFind
local Insert = table.insert
local Concat = table.concat

--* Tokenizer *--
local Tokenizer = Class{
  __init__ = function(self, String)
    self.CurPos = 1
    self.CharStream = StringToTable(String)
    self.CurChar = self.CharStream[self.CurPos]
  end;

  Peek = function(self)
    self.CurPos = self.CurPos + 1
    self.CurChar = self.CharStream[self.CurPos]
    return self.CurChar
  end;
  Check = function(self)
    return self.CharStream[self.CurPos + 1]
  end;

  SkipOptionalWhitespaces = function(self)
    if self:IsBlank(self.CurChar) then
      self:ReadBlank(); self:Peek()
    end
  end;

  IsKeyword = function(self, Character)
    return Character and Character:match("[%w_]")
  end;
  IsBlank = function(self, Character)
    return Character == "\t" or Character == "\n" or Character == " "
  end;
  IsCodeBlock = function(self, Character)
    return Character == "{" or Character == "("
  end;
  IsComment = function(self, Character)
    return Character == "#"
  end;
  IsArrow = function(self, Character)
    return Character == "-" and self:Check() == ">"
  end;
  IsString = function(self, Character)
    return Character == "'" or Character == '"'
  end;
  IsMacro = function(self, Character)
    return Character == "@"
  end;
  IsToken = function(self, Character)
    return Character == "<"
  end;

  ReadKeyword = function(self)
        -- Use table.concat instead of multiple string
        -- concatinations to make it faster.
        local Keyword = {}
        repeat
            Insert(Keyword, self.CurChar)
        until not (self:IsKeyword(self:Check()) and self:Peek())
        
        return Concat(Keyword)
    end;
    ReadBlank = function(self)
        repeat -- Nothing
        until not (self:IsBlank(self:Check()) and self:Peek())
    end;
    ReadComment = function(self)
        repeat -- Nothing
        until not (self:Check() ~= "\n" and self:Peek())
    end;
    ReadArrow = function(self)
        self:Peek(); self:Peek()
        self:SkipOptionalWhitespaces()

        return self:ReadKeyword()
    end;
    ReadString = function(self)
        local OpeningQuote = self.CurChar

        local String = {}
        while self:Peek() ~= OpeningQuote and self.CurChar do
            Insert(String, self.CurChar)
        end;
        assert(self.CurChar, "Invalid string")
        return Concat(String)
    end;
    ReadMacro = function(self)
        self:Peek()

        local Name = self:ReadKeyword()
        self:Peek()
        self:SkipOptionalWhitespaces()
        
        local Value = {}
        if self:IsCodeBlock(self.CurChar) then
            self:Peek()
            local My_StopChars = {(self.CurChar == "(" and ")" or "}")}
            Value = {{
                TYPE = "CodeBlock",
                Value = self:ReadCodeBlock(My_StopChars)
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
                if self.CurChar == "_" then
                    Insert(AST, {
                        TYPE  = "Token",
                        Value = {
                            "Blank"
                        } 
                    })
                else
                    Insert(AST, {
                        TYPE  = "Keyword",
                        Value = self:ReadKeyword()
                    })
                end
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