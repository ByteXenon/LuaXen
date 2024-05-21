--[[
  Name: Transpiler2.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/Synthax/Transpiler/lua/Transpiler2")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local LibraryTemplate = ModuleManager:loadModule("Interpreter/Synthax/Transpiler/lua/LibraryTemplate")

--* Imports *--
local Class = Helpers.NewClass
local Format = Helpers.StringFormat
local TableFind = Helpers.TableFind
local insert = table.insert
local concat = table.concat
local rep = string.rep

--* LuaTranspiler *--
local LuaTranspiler = {}
function LuaTranspiler:new(codeInfo)
  local LuaTranspilerInstance = {}

  local indentation = 0
  local AST = codeInfo.AST
  Helpers.PrintTable(AST)
  local Macros = codeInfo.Macros

  function LuaTranspilerInstance:getIndentation(n)
    return rep("  ", (n or 0) + indentation)
  end
  function LuaTranspilerInstance:addIndentation(n)
    indentation = indentation + (n or 1)
  end

  function LuaTranspilerInstance:run()
    return self:visitCodeBlock(AST)
  end
  function LuaTranspilerInstance:visit(node)
    local nodeType = node.TYPE
    if not nodeType then
      return self:visitCodeBlock(node)
    end
    local visitMethod = self["visit" .. nodeType]
    if not visitMethod then return self:defaultVisit(node) end
    return visitMethod(self, node)
  end;
  function LuaTranspilerInstance:visitCodeBlock(node)
    local tb = {}
    for _, childNode in pairs(node) do
      insert(tb, self:visit(childNode))
    end
    return concat(tb, "\n")
  end
  function LuaTranspilerInstance:defaultVisit(node)
    Helpers.PrintTable(node)
    return ""
  end;
  function LuaTranspilerInstance:visitToken(node)
    local value = node.Value
    local name = value[1]
    return Format("if self:is{0}() and self:consume{0}() then else return end", name)
  end
  function LuaTranspilerInstance:visitKeyword(node)
    local value = node.Value
    return Format("if not self:try(self.expectCharSequence, '{0}') then return end", value)
  end
  function LuaTranspilerInstance:visitZeroOrOne(node)
    local statement = node.Statement
    local value = node.Value
    return Format(
      "if self:try(function()"
      .. "\n{0}"
      .. "\nreturn true"
      .. "\nend) then"
      .. "\n{1}"
      .. "\nend", self:visit(statement), self:visit(value))
  end
  function LuaTranspilerInstance:visitOneOrMore(node)
    local statement = {node.Statement}
    local value = node.Value
    for i,v in pairs(value) do insert(statement, v) end

    local func = Format("function()\n{0}\nreturn true\nend", self:visit(statement))
    return Format(
      "if not self:try({0}) then return end"
      .. "\nwhile self:try({0}) do end", func)
  end
  function LuaTranspilerInstance:visitSyntaxDeclaration(node)
    local name = node.Name
    local value = node.Value
    return Format(
      "function ParserInstance:__{0}__()"
      .. "\n{1}"
      .. "\nreturn true"
      .. "\nend",
      name, self:visit(value)
    )
  end

  return LuaTranspilerInstance
end

return LuaTranspiler