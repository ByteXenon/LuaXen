--[[
  Name: ASTToTokensConverter.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")

local NodeTokenTemplates = ModuleManager:loadModule("Interpreter/LuaInterpreter/ASTToTokensConverter/NodeTokenTemplates")
local Lexer = ModuleManager:loadModule("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = ModuleManager:loadModule("Interpreter/LuaInterpreter/Parser/Parser")

--* Export library functions *--
local stringifyTable = Helpers.StringifyTable
local find = table.find or Helpers.TableFind
local concat = table.concat
local insert = table.insert

--* ASTToTokensConverter *--
local ASTToTokensConverter = {}
function ASTToTokensConverter:new(astHierarchy)
  local ASTToTokensConverterInstance = {}
  for index, func in pairs(NodeTokenTemplates) do
    ASTToTokensConverterInstance[index] = func
  end

  ASTToTokensConverterInstance.ast = astHierarchy

  function ASTToTokensConverterInstance:newKeyword(value)
    return { TYPE = "Keyword", Value = value }
  end
  function ASTToTokensConverterInstance:newConstant(value)
    return { TYPE = "Constant", Value = tostring(value) }
  end
  function ASTToTokensConverterInstance:newIdentifier(value)
    return { TYPE = "Identifier", Value = value }
  end
  function ASTToTokensConverterInstance:newString(value)
    return { TYPE = "String", Value = value }
  end
  function ASTToTokensConverterInstance:newOperator(value)
    return { TYPE = "Operator", Value = value }
  end
  function ASTToTokensConverterInstance:newCharacter(value)
    return { TYPE = "Character", Value = value }
  end
  function ASTToTokensConverterInstance:newNumber(value)
    return { TYPE = "Number", Value = value }
  end
  
  function ASTToTokensConverterInstance:tokenizeNode(node)
    local nodeType = node.TYPE
    local nodeFunc = self[nodeType]
    if not nodeFunc then error(("Invalid token type: %s"):format(tostring(nodeType))) end
    local tokens = {}
    nodeFunc(self, tokens, node)

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