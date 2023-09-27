--[[
  Name: ASTObfuscator.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Obfuscator/ASTObfuscator/ASTObfuscator")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local insert = table.insert
local concat = table.concat
local random = math.random
local find = table.find or Helpers.TableFind
local tableLen = Helpers.TableLen

local ASTObfuscator = {}
function ASTObfuscator:new(ast)
  local ASTObfuscatorInstance = {}
  ASTObfuscatorInstance.ast = ast
  ASTObfuscatorInstance.renamedLocals = {}

  function ASTObfuscatorInstance:generateVariableName()
    local dict = {"I", "l"}
    local str = {}
    for i = 1, 32 do
      insert(str, dict[random(1, #dict)])
    end
    local str = concat(str)
    if find(self.renamedLocals, str) then
      return self:generateVariableName()
    end

    return str
  end
  function ASTObfuscatorInstance:processNode(node)
    local nodeType = node.TYPE
    if nodeType == "LocalVariable" then
      node.Expressions = self:processNodeList(node.Expressions)
      for index, variable in ipairs(node.Variables) do
        local oldVariableName = variable.Value
        local newVariableName = self:generateVariableName()
        variable.Value = newVariableName
        self.renamedLocals[oldVariableName] = newVariableName
      end
    elseif nodeType == "Identifier" then
      local value = node.Value
      local newLocalName = self.renamedLocals[value]
      if newLocalName then node.Value = newLocalName end
    elseif nodeType == "Operator" then
      node.Left = self:processNode(node.Left)
      node.Right = self:processNode(node.Right)
    elseif nodeType == "UnaryOperator" then
      node.Operand = self:processNode(node.Operand)
    elseif nodeType == "FunctionCall" then
      node.Parameters = self:processNodeList(node.Parameters)
      node.Expression = self:processNode(node.Expression)
    elseif nodeType == "Function" then
      node.CodeBlock = self:processNodeList(node.CodeBlock)
    elseif nodeType == "Do" then
      node.CodeBlock = self:processNodeList(node.CodeBlock)
    elseif nodeType == "WhileLoop" then
      node.CodeBlock = self:processNodeList(node.CodeBlock)
      node.Expression = self:processNodeList(node.Expression)
    elseif nodeType == "Return" then
      node.Expressions = self:processNodeList(node.Expressions)
    elseif nodeType == "GenericFor" then
      node.CodeBlock = self:processNodeList(node.CodeBlock)
      node.Expression = self:processNode(node.Expression)
    elseif nodeType == "NumericFor" then
      node.CodeBlock = self:processNodeList(node.CodeBlock)
      node.Expressions = self:processNodeList(node.Expressions)
    end

    return node
  end
  function ASTObfuscatorInstance:processNodeList(nodeList)
    for index, node in ipairs(nodeList) do
      nodeList[index] = self:processNode(node)
    end
    return nodeList
  end
  function ASTObfuscatorInstance:run()
    return self:processNodeList(self.ast)
  end

  return ASTObfuscatorInstance
end

return ASTObfuscator