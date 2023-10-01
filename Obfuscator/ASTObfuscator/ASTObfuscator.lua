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
  function ASTObfuscatorInstance:processOperator(node)
    --[[
      Operator1 \ Operator2 	+ 	- 	* 	/ 	^
      + 	y(x) = x - C 	y(x) = x + C 	y(x) = C / x 	y(x) = C * x 	y(x) = log_{x + C}(C)
      - 	y(x) = x + C 	y(x) = x - C 	y(x) = -C / x 	y(x) = -C * x 	y(x) = log_{x - C}(C)
      * 	y(x) = C / x 	y(x) = -C / x 	y(x) = sqrt[C]{x} 	y(x) = x ^ 2 / C 	y(x) = 1/C
      / 	y(x) = C * x 	y(x) = -C * x 	y(x) = x ^ 2 / C 	y(x) = sqrt[C]{x} 	y(x) = 1/C
      ^ 	y(x) = log_{x}(C) 	y(x) = log_{-x}(C) 	y(x) = log_{sqrt[C]{x}}(C) 	y(x) = log_{x ^ 2 / C}(C) 	y(x)=log_{x^C}(C)
    ]]
    local randomNum = math.random(1, 9999)
    local newNode = {
      TYPE = "Operator",
      Value = "/",
      Right = {
        TYPE = "Operator",
        Value = "*",
        Left = node,
        Right = {
          TYPE = "Number",
          Value = randomNum
        }
      },
      Left = {
        Value = "+",
        TYPE = "Operator",
        Left = {
          TYPE = "Number",
          Value = randomNum
        },
        Right = node 
      }
    }
    return newNode
  end
  function ASTObfuscatorInstance:processNode(node)
    local nodeType = node.TYPE
    node.Expressions = node.Expressions and self:processNodeList(node.Expressions)
    node.Expression = node.Expression and self:processNode(node.Expression)
    node.CodeBlock = node.CodeBlock and self:processNodeList(node.CodeBlock)

    if nodeType == "LocalVariable" then
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
      node = self:processOperator(node)
      --node.Left = self:processNode(node.Left)
      --node.Right = self:processNode(node.Right)
    elseif nodeType == "UnaryOperator" then
      node.Operand = self:processNode(node.Operand)
    elseif nodeType == "FunctionCall" then
      node.Parameters = self:processNodeList(node.Parameters)
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