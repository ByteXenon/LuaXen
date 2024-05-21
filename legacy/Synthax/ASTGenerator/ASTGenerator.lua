--[[
  Name: ASTGenerator.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/ASTGenerator/ASTGenerator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

--* Imports *--
local CopyTableElements = Helpers.CopyTableElements
local StringToTable = Helpers.StringToTable
local ClearTable = Helpers.ClearTable
local Class = Helpers.NewClass
local Find = Helpers.TableFind
local Insert = table.insert
local Concat = table.concat

local Quantifiers = {
  ["*"] = "ZeroOrMore",
  ["?"] = "ZeroOrOne",
  ["+"] = "OneOrMore"
}

--* GroupVisitor *--
local GroupVisitor; GroupVisitor = Class{
  __init__ = function(self, Node, Macros)
    self.AST = {}
    self.Macros = Macros or {}
    self.Parent = Node

    self.NodeIndex = 1
    self.CurrentNode = self.Parent[self.NodeIndex]
  end;
  Peek = function(self, n)
    return self.Parent[self.NodeIndex + (n or 1)]
  end;

  Consume = function(self, n)
    self.NodeIndex = self.NodeIndex + (n or 1)
    self.CurrentNode = self.Parent[self.NodeIndex]
    return self.CurrentNode
  end;

  DefaultVisit = function(self, Node)
    return Node
  end;
  
  _IsQuantifier = function(self, Node)
    if not Node.TYPE == "Character" then return end
    local Character = Node.Value

    if Quantifiers[Character] then
     return true
    end
  end; -- Node here is a current node, not the character (next) one.
  _VisitQuantifier = function(self, Node, CharacterNode)
    local Character = CharacterNode.Value
    local QuanitiferName = Quantifiers[Character]
    local Statement, Value;

    if Node.TYPE ~= "CodeBlock" then
      Statement = {
        TYPE      = Node.TYPE,
        Value     = Node.Value,
        Statement = Node.Statement
      }
      Value = {}
    else
      Statement = Node.Value[1]
      Value = { select(2, unpack(Node.Value) ) }
    end

    local ReturnNode = {
      TYPE = QuanitiferName,
      Statement = Statement,
      Value = Value
    }

    return ReturnNode
  end;

  Visit = function(self, Node)
    local Type = Node.TYPE or "Group"
    local VisitorFunction = self["Visit" .. Type]
    
    if not VisitorFunction then
      VisitorFunction = self.DefaultVisit
    end

    return VisitorFunction(self, Node)
  end;

  VisitCodeBlock = function(self, Node)
    local Value = Node.Value
    local NewNode = {
      TYPE  = "CodeBlock",
      Value = GroupVisitor(Value, self.Macros):RunVisitor().AST
    }

    return NewNode
  end;

  VisitCharacter = function(self, Node)
    local Character = Node.Value
    local LastSavedNode = self.AST[#self.AST]
    
    if self:_IsQuantifier(Node) then
      local NewLastSavedNode = self:_VisitQuantifier(LastSavedNode, Node)
      CopyTableElements(NewLastSavedNode, ClearTable(LastSavedNode))
      return
    elseif Character == ":" then
      local NextNode = self:Visit(self:Consume())

      local NewLastSavedNode = {
        TYPE  = "SyntaxDeclaration",
        Name  = LastSavedNode.Value,
        Value = NextNode.Value
      }
      CopyTableElements(NewLastSavedNode, ClearTable(LastSavedNode))
      return
    end

    return self:DefaultVisit(Node)
  end;

  VisitArrow = function(self, Node)
    local LastSavedNode = self.AST[#self.AST]
    LastSavedNode["AST"] = Node["Value"]
    return
  end;

  VisitMacro = function(self, Node)
    local MacroName = Node["Name"]
    local Value = Node.Value
    if MacroName == "object" then
      self.Macros[MacroName] = Value
    end
    return
  end;

  RunVisitor = function(self)
    local AST = self.AST

    while self.CurrentNode do
      local NewNode = self:Visit(self.CurrentNode)
      if NewNode then
        table.insert(AST, NewNode)
      end
      self:Consume()
    end

    return {
      AST = self.AST,
      Macros = self.Macros
    }
  end;
}

--* ASTGenerator *--
local ASTGenerator = Class{
  __init__ = function(self, Tokens)
    self.Tokens = Tokens
  end;
  GroupVisitor = GroupVisitor;
  GenerateAST = function(self)
    return self.GroupVisitor(self.Tokens):RunVisitor()
  end
}

return ASTGenerator