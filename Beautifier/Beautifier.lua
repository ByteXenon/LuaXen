--[[
  Name: Beautifier.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Beautifier/Beautifier")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* Beautifier *--
local Beautifier = {}
function Beautifier:new(codeOrAST)
  local BeautifierInstance = {}
  BeautifierInstance.ast = codeOrAST
  
  if type(codeOrAST) == "string" then
    local Tokens = Lexer:new(Code):tokenize()
    local AST = Parser:new(Tokens):parse()
    BeautifierInstance.ast = AST
  end


  function BeautifierInstance:addSpaces(indentationLevel)
    return rep("  ", indentationLevel)
  end
  function BeautifierInstance:expressionListToStr(list)
    local processedExpressionList = {}
    for _, node in ipairs(list) do
      insert(processedExpressionList, self:processExpression(node))
    end
    return #processedExpressionList ~= 0 and concat(processedExpressionList, ",")
  end
  function BeautifierInstance:processExpression(node)
    local type = node.TYPE
    Helpers.PrintTable(node)
    if type == "Identifier" or type == "Number" then
      local value = node.Value
      return value
    elseif type == "String" then
      local value = node.Value
      value = "'" .. value .. "'"
      return value
    elseif type == "Operator" then
      local operand = node.Operand
      if operand then
        return
      end
      local left, right = node.Left, node.Right
      local processedLeft = self:processExpression(left)
      local processedRight = self:processExpression(right)
      return processedLeft .. " " .. node.Value .. " " .. processedRight
    end
  end
  function BeautifierInstance:processNode(node, indentationLevel)
    local type = node.TYPE
    if type == "LocalVariable" then
      local varListStr = self:expressionListToStr(node.Variables)
      local expressionListStr = self:expressionListToStr(node.Expressions)
      
      local newLine = self:addSpaces(indentationLevel) .. "local " .. varListStr
      if expressionListStr then newLine = newLine .. " = " .. expressionListStr end
      
      return newLine .. ";"
    elseif type == "IfStatement" then
      return "if " .. self:processExpression(node.Statement) .. " then"
             .. self:processCodeBlock(node.CodeBlock, indentationLevel + 1)
             .. "\nend"
    end
  end

  function BeautifierInstance:processCodeBlock(codeBlock, indentationLevel)
    local indentationLevel = indentationLevel or 0

    local code = ""
    for _, node in ipairs(codeBlock) do
      local newLine = self:processNode(node, indentationLevel)
      if newLine then code = code .. "\n" .. newLine end
    end

    return code
  end
  function BeautifierInstance:run()
    return self:processCodeBlock(self.ast)
  end

  return BeautifierInstance
end

return Beautifier