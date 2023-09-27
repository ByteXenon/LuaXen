--[[
  Name: ASTToTokensConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert

--* ASTToTokensConverter *--
local ASTToTokensConverter = {}
function ASTToTokensConverter:new(codeOrAST)
  local ASTToTokensConverterInstance = {}
  ASTToTokensConverterInstance.ast = codeOrAST
  if type(codeOrAST) == "string" then
    local Tokens = Lexer:new(Code):tokenize()
    local AST = Parser:new(Tokens):parse()
    ASTToTokensConverterInstance.ast = AST
  end

  function ASTToTokensConverterInstance:newKeyword(value)
    return { TYPE = "Keyword", Value = value }
  end
  function ASTToTokensConverterInstance:newIdentifier(value)
    return { TYPE = "Identifier", Value = value }
  end
  function ASTToTokensConverterInstance:newString(value)
    return { TYPE = "String", Value = value }
  end
  function ASTToTokensConverterInstance:newCharacter(value)
    return { TYPE = "Character", Value = value }
  end
  function ASTToTokensConverterInstance:newNumber(value)
    return { TYPE = "Number", Value = value }
  end
  
  function ASTToTokensConverterInstance:tokenizeNode(node)
    local nodeType = node.TYPE
    local tokens = {}

    if nodeType == "Identifier" then
      insert(tokens, self:newIdentifier(node.Value))
    elseif nodeType == "Number" then
      insert(tokens, self:newNumber(node.Value))
    elseif nodeType == "String" then
      insert(tokens, self:newString(node.Value))
    elseif nodeType == "Operator" then
      local left = self:tokenizeNode(node.Left)
      local right = self:tokenizeNode(node.Right)
      for _, token in ipairs(left) do
        insert(tokens, token)
      end
      insert(tokens, self:newCharacter(node.Value))
      for _, token in ipairs(right) do
        insert(tokens, token)
      end
    elseif nodeType == "UnaryOperator" then
      local operand = self:tokenizeNode(node.Operand)
      insert(tokens, self:newCharacter(node.Value))
      for _, token in ipairs(operand) do
        insert(tokens, token)
      end
    elseif nodeType == "LocalVariable" then
      insert(tokens, self:newKeyword("local"))
      for index, variable in ipairs(node.Variables) do
        insert(tokens, variable)
        if index ~= #node.Variables then insert(tokens, self:newCharacter(",")) end
      end
      insert(tokens, self:newCharacter("="))
      for index, expression in ipairs(node.Expressions) do
        local tokenizedExpression = self:tokenizeNode(expression)
        for index2, token in ipairs(tokenizedExpression) do
          insert(tokens, token)
        end
        if index ~= #node.Expressions then insert(tokens, self:newCharacter(",")) end
      end
    elseif nodeType == "IfStatement" then
      insert(tokens, self:newKeyword("if"))
      for index, token in ipairs(self:tokenizeNode(node.Condition)) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("then"))
      for index, token in ipairs(self:tokenizeCodeBlock(node.CodeBlock)) do
        insert(tokens, token)
      end
      for _, elseIf in ipairs(node.ElseIfs) do
        insert(tokens, self:newKeyword("elseif"))
        for index, token in ipairs(self:tokenizeNode(elseIf.Condition)) do
          insert(tokens, token)
        end
        insert(tokens, self:newKeyword("then"))
        for index, token in ipairs(self:tokenizeCodeBlock(elseIf.CodeBlock)) do
          insert(tokens, token)
        end
      end
      if node.Else and node.Else.TYPE then
        insert(tokens, self:newKeyword("else"))
        for index, token in ipairs(self:tokenizeCodeBlock(node.Else.CodeBlock)) do
          insert(tokens, token)
        end
      end
      insert(tokens, self:newKeyword("end"))
    elseif nodeType == "Function" then
      insert(tokens, self:newKeyword("function"))
      insert(tokens, self:newCharacter("("))
      for _, argument in ipairs(node.Arguments) do
        insert(tokens, argument)
      end
      insert(tokens, self:newCharacter(")"))
      for index, token in ipairs(self:tokenizeCodeBlock(node.CodeBlock)) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("end"))
    --  expressionType ~= "Identifier" and expressionType ~= "Index"
    elseif nodeType == "FunctionCall" then
      local expression = node.Expression
      local parameters = node.Parameters
      
      if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" then
        insert(tokens, self:newCharacter("("))
      end 
      for _, token in ipairs(self:tokenizeNode(expression)) do
        insert(tokens, token)
      end
      if expression.TYPE ~= "Identifier" and expression.TYPE ~= "Index" then
        insert(tokens, self:newCharacter(")"))
      end
      insert(tokens, self:newCharacter("("))
      for index, parameter in ipairs(parameters) do
        for index2, token in ipairs(self:tokenizeNode(parameter)) do
          insert(tokens, token)
        end
        if index ~= #parameters then insert(tokens, self:newCharacter(",")) end
      end
      insert(tokens, self:newCharacter(")"))
    elseif nodeType == "WhileLoop" then
      local expression = self:tokenizeNode(node.Expression)
      local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)

      insert(tokens, self:newKeyword("while"))
      for index, token in ipairs(expression) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("do"))
      for index, token in ipairs(codeBlock) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("end"))
    elseif nodeType == "GenericFor" then
      local expression = self:tokenizeNode(node.Expression)
      local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
      local iteratorVariables = node.IteratorVariables

      insert(tokens, self:newKeyword("for"))
      for index, variableName in ipairs(iteratorVariables) do
        insert(tokens, self:newIdentifier(variableName))
        if index ~= #iteratorVariables then
          insert(tokens, self:newCharacter(","))
        end
      end
      insert(tokens, self:newKeyword("in"))
      for index, token in ipairs(expression) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("do"))
      for index, token in ipairs(codeBlock) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("end"))
    elseif nodeType == "NumericFor" then
      local expressions = node.Expressions
      local codeBlock = self:tokenizeCodeBlock(node.CodeBlock)
      local iteratorVariables = node.IteratorVariables

      insert(tokens, self:newKeyword("for"))
      for index, variableName in ipairs(iteratorVariables) do
        insert(tokens, self:newIdentifier(variableName))
        if index ~= #iteratorVariables then
          -- There shouldn't be more than 1 iterator variable,
          -- but I'll make it future-proof and add the extra commas
          -- just in case
          insert(tokens, self:newCharacter(","))
        end
      end
      insert(tokens, self:newCharacter("="))
      for index, token in ipairs(expressions) do
        insert(tokens, token)
        if index ~= #expressions then
          insert(tokens, self:newCharacter(","))
        end
      end
      insert(tokens, self:newKeyword("do"))
      for index, token in ipairs(codeBlock) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("end")) 
    elseif nodeType == "Table" then
      insert(tokens, self:newCharacter("{"))
      for index, element in ipairs(node.Elements) do
        insert(tokens, self:newCharacter("["))
        for _, token in ipairs(self:tokenizeNode(element.Key)) do
          insert(tokens, token)
        end
        insert(tokens, self:newCharacter("]"))
        insert(tokens, self:newCharacter("="))
        for _, token in ipairs(self:tokenizeNode(element.Value)) do
          insert(tokens, token)
        end
        if index ~= #node.Elements then insert(tokens, self:newCharacter(",")) end
      end
      insert(tokens, self:newCharacter("}"))
    elseif nodeType == "Return" then
      insert(tokens, self:newKeyword("return"))
      for index, expression in ipairs(node.Expressions) do
        for _, token in ipairs(self:tokenizeNode(expression)) do
          insert(tokens, token)
        end
        if index ~= #node.Expressions then insert(tokens, self:newCharacter(",")) end
      end
    elseif nodeType == "Do" then
      insert(tokens, self:newKeyword("do"))
      for index, token in ipairs(self:tokenizeCodeBlock(node.CodeBlock)) do
        insert(tokens, token)
      end
      insert(tokens, self:newKeyword("end"))
    elseif nodeType == "Index" then
       
      for index, token in ipairs(self:tokenizeNode(node.Expression)) do
        insert(tokens, token)
      end
      insert(tokens, self:newCharacter("."))
      if node.Index.TYPE == "String" and node.Index.Value:match("^[%a_].*") then
        insert(tokens, self:newIdentifier(node.Index.Value))
      else
        for index, token in ipairs(self:tokenizeNode(node.Index)) do
          insert(tokens, token)
        end
      end
    else
      Helpers.PrintTable(node)
    end
    return tokens
  end
  function ASTToTokensConverterInstance:tokenizeCodeBlock(list)
    local tokens = {}
    for index, node in ipairs(list) do
      local returnedTokens = self:tokenizeNode(node)
      for index, token in ipairs(returnedTokens) do
        insert(tokens, token)
      end
    end
    return tokens
  end
  function ASTToTokensConverterInstance:run()
    return self:tokenizeCodeBlock(self.ast)
  end

  return ASTToTokensConverterInstance
end

return ASTToTokensConverter