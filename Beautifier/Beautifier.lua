--[[
  Name: Beautifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Beautifier/Beautifier")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")
local LuaTemplates = ModuleManager:loadModule("Beautifier/LuaSyntaxTemplates")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

local function stringFormat(str, formatTb)
  str = str:gsub("{([\1-\124\126-\255]+)}", function(formatValue)
    local foundFormatValue = formatTb[formatValue]
    if foundFormatValue then return foundFormatValue end
    return "" -- formatValue
  end)
  return str
end

--* Beautifier *--
local Beautifier = {}
function Beautifier:new(astHierarchy)
  local BeautifierInstance = {}
  BeautifierInstance.ast = astHierarchy
  BeautifierInstance.indentationLevel = 0;

  function BeautifierInstance:addSpaces(n)
    return rep("  ", self.indentationLevel + (n or 0))
  end
  function BeautifierInstance:increaseIndentation(n)
    self.indentationLevel = self.indentationLevel + (n or 1)
  end
  function BeautifierInstance:decreaseIndentation(n)
    self.indentationLevel = self.indentationLevel - (n or 1)
  end
  function BeautifierInstance:setIndentation(value)
    self.indentationLevel = value
  end

  function BeautifierInstance:expressionListToStr(list)
    local processedExpressionList = {}
    for _, node in ipairs(list) do
      local processedNode = self:processNode(node)
      insert(processedExpressionList, processedNode )
    end
    return concat(processedExpressionList, ", ")
  end
  
  function BeautifierInstance:processNode(node, isInCodeBlock)
    local nodeType = node.TYPE
    if nodeType == "Expression" or nodeType == "AST" or nodeType == "Group" then
      return self:processNode(node.Value, isInCodeBlock)
    end
    local currentIndentation = self:addSpaces()
    local codeBlock = (node.CodeBlock and self:processCodeBlock(node.CodeBlock, 1))
    local formatTable = {
      indentation = currentIndentation,
      codeBlockIndentation = (isInCodeBlock and currentIndentation) or "",
      postCodeBlockIndentation = (codeBlock == " " and "") or currentIndentation,

      name = node.Name,
      value = (node.Value),
      index = (node.Index and self:processNode(node.Index)),
      constant = (tostring(node.Value)),
      expression = (node.Expression and self:processNode(node.Expression)),
      condition = (node.Condition and self:processNode(node.Condition)),
      expressions = (node.Expressions and self:expressionListToStr(node.Expressions)),
      parameters = (node.Parameters and self:expressionListToStr(node.Parameters)),
      codeBlock = codeBlock,
      variables = (node.Variables and self:expressionListToStr(node.Variables)),
      iteratorVariables = (node.IteratorVariables and concat(node.IteratorVariables, ", ")),
      arguments = (node.Arguments and self:expressionListToStr(node.Arguments)),
      leftExpression = (node.Left and self:processNode(node.Left)),
      rightExpression = (node.Right and self:processNode(node.Right)),
      operand = (node.Operand and self:processNode(node.Operand))
    }

    local nodeFunctionTemplate = LuaTemplates.FunctionTemplates[nodeType]
    if nodeFunctionTemplate then
      return nodeFunctionTemplate(self, node, isInCodeBlock, formatTable)
    end

    local nodeStringTemplate = LuaTemplates.StringTemplates[nodeType]
    if not nodeStringTemplate then
      error("Unsupported node: " .. node.TYPE)
    end

    return stringFormat(nodeStringTemplate, formatTable)
  end
  function BeautifierInstance:processCodeBlock(codeBlock, indentationLevel, isMainBlock)
    if indentationLevel then self:increaseIndentation(indentationLevel) end

    local lines = {}
    for _, node in ipairs(codeBlock) do
      local newLine = self:processNode(node, true)
      if newLine then insert(lines, newLine) end
    end

    if indentationLevel then self:decreaseIndentation(indentationLevel) end
    if #lines == 0 then return " " end
    if isMainBlock then return concat(lines, "\n") end
    return "\n" .. concat(lines, "\n") .. "\n"
  end

  function BeautifierInstance:run()
    return self:processCodeBlock(self.ast, nil, true)
  end

  return BeautifierInstance
end

return Beautifier