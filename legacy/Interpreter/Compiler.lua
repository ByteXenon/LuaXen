--[[
  Name: Compiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

local Helpers = require("Helpers/Helpers")
local Transpiler = require("Interpreter/Transpiler")

local Class = Helpers.NewClass
local Find = Helpers.TableFind
local Format = Helpers.StringFormat

--[[
    ChainingParser:
        __init__(self, String)
        Parse(self):
            Parser:
                Peek(self)
                Check(self)
]]

local ChainingParser = Class{
    __init__ = function(self, String)
        Parser.CurPos = 1
        Parser.CharStream = Helpers.StringToTable(String)
        Parser.CurChar = Parser.CharStream[Parser.CurPos]
    end;
    Parse = function(self)
        local super = self
        local Parser = Class{
            
        }
    end
}

return ChainingParser

function ChainingParser.Parse(String)
    local Parser = {}

    function Parser.__init__()
        Parser.CurPos = 1
        Parser.CharStream = Helpers.StringToTable(String)
        Parser.CurChar = Parser.CharStream[Parser.CurPos]
        return Parser
    end

    function Parser.Peek()
        Parser.CurPos = Parser.CurPos + 1
        Parser.CurChar = Parser.CharStream[Parser.CurPos]
        return Parser.CurChar
    end

    function Parser.Check()
        return Parser.CharStream[Parser.CurPos + 1]
    end

    function Parser.GenerateAST()
        -- Actually it makes an AST too, but
        -- since we make a complete AST with another
        -- function, i'd call it just tokenizing
        local function Tokenize()
            local Syntax = {}

            function Syntax.IsKeyword(Character)
                return Character and Character:match("[%w_]")
            end; function Syntax.ReadKeyword()
                local Keyword = {}
                repeat
                    table.insert(Keyword, Parser.CurChar)
                until not (Syntax.IsKeyword(Parser.Check()) and Parser.Peek())
                
                return table.concat(Keyword)
            end

            function Syntax.IsBlank(Character)
                return Character == "\t" or Character == " " or Character == "\n"
            end; function Syntax.ReadBlank()
                repeat
                    -- Nothing
                until not (Syntax.IsBlank(Parser.Check()) and Parser.Peek())
            end

            function Syntax.SkipOptionalWhitespaces()
                if Syntax.IsBlank(Parser.CurChar) then
                    Syntax.ReadBlank(); Parser.Peek()
                end
            end

            function Syntax.IsComment(Character)
                return Character == "#"
            end; function Syntax.ReadComment()
                repeat
                    -- Nothing
                until not (Parser.Check() ~= "\n" and Parser.Peek())
            end

            function Syntax.IsArrow(Character)
                return Character == "-" and Parser.Check() == ">"
            end; function Syntax.ReadArrow()
                Parser.Peek(); Parser.Peek();
                Syntax.SkipOptionalWhitespaces()
                
                return Syntax.ReadKeyword()
            end

            function Syntax.IsString(Character)
                return Character == "'" or Character == '"'
            end; function Syntax.ReadString()
                local OpeningQuote = Parser.CurChar;
                
                local String = {}
                while Parser.Peek() ~= OpeningQuote do
                    table.insert(String, Parser.CurChar)
                end; if Parser.CurChar ~= OpeningQuote then
                    return error("Invalid string")
                end

                return table.concat(String)
            end

            function Syntax.IsMacro(Character)
                return Character == "@"
            end; function Syntax.ReadMacro()
                Parser.Peek()

                local Name = Syntax.ReadKeyword()
                local Value = {}

                Parser.Peek()
                Syntax.SkipOptionalWhitespaces()

                if Syntax.IsCodeBlock(Parser.CurChar) then
                    Parser.Peek()
                    
                    local My_StopChars = {(Parser.CurChar == "(" and ")" or "}")}
                    Value = {{
                        TYPE = "CodeBlock",
                        Value = Syntax.ReadCodeBlock(My_StopChars)
                    }}
                elseif Syntax.IsKeyword(Parser.CurChar) then
                    local NewKeyword = Syntax.ReadKeyword()
                    Value = {{
                        TYPE = "Keyword",
                        Value = NewKeyword
                    }}
                elseif Syntax.IsString(Parser.CurChar) then
                    local NewString = Syntax.ReadString()
                    Value = {{
                        TYPE = "Keyword",
                        Value = NewString
                    }}
                else
                    repeat 
                        table.insert(Value, Parser.CurChar) 
                    until not (Parser.Check() ~= "\n" and Parser.Peek())
                
                    Value = {{
                        TYPE = "Keyword",
                        Value = table.concat(Value)
                    }}
                end

                return Name, Value
            end

            function Syntax.IsToken(Character)
                return Character == "<"
            end; function Syntax.ReadToken()
                Parser.Peek()

                local function GetParams()
                    local Params = {}
                    
                    local GetNextParam;
                    function GetNextParam()
                        if Syntax.IsBlank(Parser.CurChar) then
                            Syntax.ReadBlank(); Parser.Peek()
                        end

                        local CurrentParam;
                        if Syntax.IsKeyword(Parser.CurChar) then
                            CurrentParam = Syntax.ReadKeyword()
                        elseif Parser.CurChar == "%" then
                            Parser.Peek()
                            -- That would be funny if it hang it right here.
                            CurrentParam = "%" .. Syntax.ReadKeyword()
                        elseif Parser.CurChar == ">" then
                            return
                        end

                        Parser.Peek()
                        table.insert(Params, CurrentParam)
                        
                        return GetNextParam()
                    end

                    GetNextParam()
                    return Params
                end
               
                return GetParams()
            end

            function Syntax.IsCodeBlock(Character)
                return Character == "{" or Character == "("
            end; function Syntax.ReadCodeBlock(StopChars)
                local AST = {}
                
                repeat
                    if StopChars and Find(StopChars, Parser.CurChar) then
                        return AST
                    elseif Parser.CurChar == "}" or Parser.CurChar == ")" then
                        return error("Unexpected end of code block")
                    elseif Syntax.IsBlank(Parser.CurChar) then
                        Syntax.ReadBlank()
                    elseif Syntax.IsComment(Parser.CurChar) then
                        Syntax.ReadComment()
                    elseif Syntax.IsToken(Parser.CurChar) then
                        table.insert(AST, 
                            {
                                TYPE = "Token",
                                Value = Syntax.ReadToken()
                            }
                        )
                    elseif Syntax.IsKeyword(Parser.CurChar) then
                        table.insert(AST, 
                            {
                                TYPE = "Keyword",
                                Value = Syntax.ReadKeyword()
                            }
                        )
                    elseif Syntax.IsMacro(Parser.CurChar) then
                        local Name, Value = Syntax.ReadMacro()
                        table.insert(AST,
                            {
                                TYPE = "Macro",
                                Name = Name,
                                Value = Value
                            }
                        )
                    elseif Syntax.IsCodeBlock(Parser.CurChar) then
                        local My_StopChars = {(Parser.CurChar == "(" and ")" or "}")}
                        Parser.Peek()

                        table.insert(AST, 
                            {
                                TYPE = "CodeBlock",
                                Value = Syntax.ReadCodeBlock(My_StopChars)
                            }
                        )
                    elseif Syntax.IsString(Parser.CurChar) then
                        table.insert(AST, 
                            {
                                TYPE = "String",
                                Value = Syntax.ReadString()
                            }
                        )
                    elseif Syntax.IsArrow(Parser.CurChar) then
                        table.insert(AST,
                            {
                                TYPE = "Arrow",
                                Value = Syntax.ReadArrow()
                            }
                        )
                    else
                        table.insert(AST, 
                            {
                                TYPE = "Character",
                                Value = Parser.CurChar
                            }
                        )
                    end
                until not (Parser.Peek())

                return AST
            end

            return Syntax.ReadCodeBlock()
        end

        local function MakeAST(Nodes)
            
            local VisitGroup;
            function VisitGroup(Nodes)
                local ReturnTb = {}
                
                local Quantifiers = {
                    ["*"] = "ZeroOrMore",
                    ["+"] = "WhileStatement",
                    ["?"] = "IfStatement"
                }
                -- The "AND" operator is freaking useless
                -- Just made it for the future compability
                local Operators = { 
                    ["|"] = "OR",
                    ["&"] = "AND"
                }
                
                local NodeIndex = 1

                -- Visitor table
                local Visitor = {}

                -- Visitor functions
                function Visitor.VisitToken(Node)
                    table.insert(ReturnTb, Node)

                    return Node
                end

                function Visitor.VisitCharacter(Node)
                    local Value = Node["Value"]
                    
                    if Value == ":" then
                        
                    elseif Quantifiers[Value] and ReturnTb[#ReturnTb] then
                        local LastNode = ReturnTb[#ReturnTb]
                        local LastNodeType = LastNode["TYPE"] or "Group"

                        -- "?" Sign is a "if" statement, to make apply the Visitor Pattern
                        -- more preciously, we make a new type "IfStatement"
                        --if Value == "?" or Value == "*" then
                        local Statement, NewValue;

                        if LastNodeType ~= "Group" then
                            Statement = LastNode
                        else
                            Statement = LastNode["Value"][1]
                        
                            if LastNode["Value"][2] then
                                NewValue = {
                                    TYPE = "Group",
                                    Value = { select(2, unpack(LastNode["Value"])) }
                                }
                            end
                        end

                        ReturnTb[#ReturnTb] = {
                            TYPE = Quantifiers[Value],
                            Statement = Statement,
                            Value = NewValue
                        }

                        return
                    elseif Operators[Value] and ReturnTb[#ReturnTb] then  
                        local OperatorType = Operators[Value]
                        
                        local LastNode = ReturnTb[#ReturnTb]
                        
                        ReturnTb[#ReturnTb] = nil
                        NodeIndex = NodeIndex + 1;
                        
                        local NextNode = Nodes[NodeIndex]
                        local VisitorFunction = Visitor["Visit" .. NextNode.TYPE]
                        NextNode = VisitorFunction(NextNode)

                        local NewNode = {
                            TYPE = OperatorType,
                            Value1 = LastNode,
                            Value2 = NextNode
                        }

                        table.insert(ReturnTb, NewNode)
                        return NewNode
                    end

                    table.insert(ReturnTb, Node)
                    return Node
                end

                function Visitor.VisitKeyword(Node)
                    table.insert(ReturnTb, Node)
                    return Node
                end

                function Visitor.VisitString(Node)
                    table.insert(ReturnTb, Node)
                    return Node
                end

                function Visitor.VisitMacro(Node)
                    local NewNode = {
                        TYPE = "Group",
                        Value = VisitGroup(Node["Value"])
                    }

                    table.insert(ReturnTb, NewNode)
                    return NewNode
                end

                function Visitor.VisitArrow(Node)
                    local LastNode = ReturnTb[#ReturnTb]
                    LastNode["ReturnTb"] = Node["Value"]
                    return
                end

                function Visitor.VisitCodeBlock(Node)
                    local NewNode = {
                        TYPE = "Group",
                        Value = VisitGroup(Node["Value"])
                    } 
                    table.insert(ReturnTb, NewNode)
                    return NewNode
                end

                while Nodes[NodeIndex] do
                    local Node = Nodes[NodeIndex]
                    local Type = Node["TYPE"]
                    local VisitorFunction = Visitor["Visit" .. Type]

                    VisitorFunction(Node)
                    NodeIndex = NodeIndex + 1
                end

                return ReturnTb
            end

            return VisitGroup(Nodes)
        end

        return MakeAST(Tokenize())
    end

    Parser.__init__()
    return Parser.GenerateAST()
end

return ChainingParser