--[[
  Name: ASTPrinter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local ExpressionNodesConverters = require("Printer/ASTPrinter/Converters/ExpressionNodesConverters")
local StatementNodesConverters = require("Printer/ASTPrinter/Converters/StatementNodesConverters")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* ASTPrinterMethods *--
local ASTPrinterMethods = {}

function ASTPrinterMethods:processIdentifierList(identifiers)
  return concat(identifiers, ", ")
end

function ASTPrinterMethods:processExpressionNode(node)
  local nodeType = node.TYPE
  if nodeType == "Expression" then
    node = node.Value
    nodeType = node.TYPE
  end

  while nodeType == "Expression" do
    return "(" .. self:processExpressionNode(node.Value) .. ")"
  end

  local nodeConverter = ExpressionNodesConverters[nodeType]
  assert(nodeConverter, "No converter found for " .. tostring(nodeType))

  return nodeConverter(self, node)
end

function ASTPrinterMethods:processStatementNode(node)
  local nodeType = node.TYPE
  local nodeConverter = StatementNodesConverters[nodeType]
  assert(nodeConverter, "No converter found for " .. nodeType)

  return nodeConverter(self, node)
end

function ASTPrinterMethods:processExpressions(nodeList)
  local tb = {}
  for _, node in ipairs(nodeList) do
    insert(tb, self:processExpressionNode(node))
  end

  return concat(tb, ", ")
end

function ASTPrinterMethods:processCodeBlock(codeBlock, noIndentation)
  local oldIndentation = self.indentation
  if not noIndentation then
    self.indentation = self.indentation .. "  "
  end
  local tb = {}
  for _, node in ipairs(codeBlock) do
    local newLine = self:processStatementNode(node)
    insert(tb, newLine)
  end

  self.indentation = oldIndentation
  return concat(tb, "\n") .. "\n"
end

-- Main
function ASTPrinterMethods:print()
  local tb = {}
  for _, node in ipairs(self.ast) do
    local newLine = self:processStatementNode(node)
    insert(tb, newLine)
  end

  return concat(tb, "\n")
end


--* ASTPrinter *--
local ASTPrinter = {}
function ASTPrinter:new(ast)
  local ASTPrinterInstance = {}
  ASTPrinterInstance.ast = ast
  ASTPrinterInstance.indentation = ""

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ASTPrinterInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ASTPrinterInstance: " .. index)
      end
      ASTPrinterInstance[index] = value
    end
  end

  -- Main
  inheritModule("ASTPrinterMethods", ASTPrinterMethods)


  return ASTPrinterInstance
end

return ASTPrinter