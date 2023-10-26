--[[
  Name: Transpiler.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Transpiler/lua/Transpiler")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Export library functions *--
local Class = Helpers.NewClass
local Format = Helpers.StringFormat
local TableFind = Helpers.TableFind
local Insert = table.insert
local Concat = table.concat
local Rep = string.rep

--* LuaTranspiler *--
local LuaTranspiler = Class{
  __init__ = function(self, codeInfo)
    self.Indentation = 0
    self.AST = codeInfo.AST
    Helpers.PrintTable(self.AST)
    self.Macros = codeInfo.Macros
  end;

  GetIndentation = function(self, n)
    return Rep("  ", (n or 0) + self.Indentation)
  end;
  AddIndentation = function(self, n)
    local n = (n or 1)
    self.Indentation = self.Indentation + n
  end;
  
  FormatNode = function(self, NodeType, ...)
    local Indentation = self:GetIndentation()
    local NodeTemplate = self[NodeType .. "Template"]

    return Format(NodeTemplate, Indentation, ...)
  end;
  Visit = function(self, Node)
    local NodeType = Node.TYPE
    if not NodeType then
      return self:VisitCodeBlock(Node)
    end
    local VisitMethod = self["Visit" .. NodeType]
    
    return VisitMethod(self, Node)
  end;
  VisitMacro = function(self, Node)
    return ""
  end;

  VisitKeyword = function(self, Node)
    return self:FormatNode("Keyword", Node.Value)
  end;
  VisitString = function(self, Node)
    return self:FormatNode("String", "'"..Node.Value.."'")
  end;
  VisitCharacter = function(self, Node)
    return self:GetIndentation() .. tostring(Node.Value)
  end;
  VisitArrow = function(self, Node)
    return self:GetIndentation() .. ''
  end;
  
  VisitCodeBlock = function(self, Node)
    local Value = Node.Value or Node
    
    local Lines = {}
    for _, Value in ipairs(Value) do
      Insert(Lines, self:Visit(Value))
    end

    return Concat(Lines, "\n") 
  end;

  VisitOneOrMore = function(self, Node)
    self:AddIndentation(2)
    local Value = self:Visit(Node.Value)
    local Statement = self:Visit(Node.Statement or {})
    self:AddIndentation(-2)

    return self:FormatNode("OneOrMore", Value, Statement)
  end;
  VisitZeroOrOne = function(self, Node)
    self:AddIndentation(2)
      local Value = self:Visit(Node.Value)
      local Statement = self:Visit(Node.Statement or {})
    self:AddIndentation(-2)

    return self:FormatNode("ZeroOrOne", Value, Statement)
  end;
  VisitZeroOrMore = function(self, Node)
    self:AddIndentation(2)
      local Value = self:Visit(Node.Value)
      local Statement = self:Visit(Node.Statement or {})
    self:AddIndentation(-2)

    --return Value
    return self:FormatNode("ZeroOrMore", Value, Statement)
  end;
  
  VisitSyntaxDeclaration = function(self, Node)
    local Name = Node.Name
    local Value = Node.Value

    self:AddIndentation(1)
    local ValueLines = {}
    for _, Value in ipairs(Value) do
      Insert(ValueLines, self:Visit(Value))
    end
    self:AddIndentation(-1)

    ValueStr = Concat(ValueLines, "\n")
    return self:FormatNode("SyntaxDeclaration", Name, ValueStr)
  end;
  VisitToken = function(self, Node)
    local TokenName = Node.Value[1]
    local Arguments = { select(2, unpack(Node.Value)) }
    for i,v in ipairs(Arguments) do
      Arguments[i] = "'"..v.."'"
    end

    local KnownTokens = {
      "Blank", "Keyword"
    }
    if TableFind(KnownTokens, TokenName) then
      return self:FormatNode("KnownToken", TokenName, unpack(Arguments))
    end
    return self:FormatNode("Token", TokenName, unpack(Arguments))
  end;

  Transpile = function(self)
    local objectName = self.Macros.object and self.Macros.object[1].Value or "Parser"
    local CurrentIndentation = self:GetIndentation()
    
    self:AddIndentation()
    return Format(
            "{0}(function(self)"
            .. "\n{0}  self:__init__({1}, {2}, {3})"
            .. "\n" .. self:Visit(self.AST)
            .. "\n{0}end)({4})",
            CurrentIndentation, nil, nil, nil, objectName
          )
  end
}

return LuaTranspiler