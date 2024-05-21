--[[
  Name: IronBrikked.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]

-- This is the backend of the obfuscator
-- This script will not be placed in final obfuscated code

--* Dependencies *--
local Helpers    = require("Helpers/Helpers")
local Crypt      = require("Crypt/Crypt")
local Minifier   = require("Minifier/Minifier")
local Printer    = require("Printer/Printer")
local ASTPrinter = require("Printer/ASTPrinter/ASTPrinter")
local ASTWalker  = require("ASTWalker/ASTWalker")

local LuaInterpreter    = require("Interpreter/LuaInterpreter/LuaInterpreter")
local InstructionsSpecs = require("Obfuscator/IronBrikked/InstructionsSpecs")

local Lexer                = LuaInterpreter.modules.Lexer
local Parser               = LuaInterpreter.modules.Parser
local ASTToTokensConverter = LuaInterpreter.modules.ASTToTokensConverter
local NodeFactory          = LuaInterpreter.modules.NodeFactory

--* Imports *--
local insert = table.insert
local concat = table.concat
local floor  = math.floor
local abs    = math.abs
local char   = string.char
local sub    = string.sub

local createIfStatementNode     = NodeFactory.createIfStatementNode
local createElseStatementNode   = NodeFactory.createElseStatementNode
local createOperatorNode        = NodeFactory.createOperatorNode
local createLocalVariableNode   = NodeFactory.createLocalVariableNode
local createNumberNode          = NodeFactory.createNumberNode

local readFile      = Helpers.readFile
local deepCopyTable = Helpers.deepCopyTable

local writeOneByte   = Crypt.Binary.makeOneByteLittleEndian
local writeTwoBytes  = Crypt.Binary.makeTwoBytesLittleEndian
local writeFourBytes = Crypt.Binary.makeFourBytesLittleEndian
local writeDouble    = Crypt.Binary.makeDoubleLittleEndian
local writeString    = Crypt.Binary.makeStringLittleEndian
local toBase36       = Crypt.Conversion.toBase36
local lzwCompress    = Crypt.Compression.lzwCompress

local opcodeToNumberLookup = InstructionsSpecs.OpcodeToNumberLookup
local supersetInstructions = InstructionsSpecs.SupersetInstructions
local opmodes              = InstructionsSpecs.Opmodes

--* Constants *--
local MODE_iABC  = 0
local MODE_iABx  = 1
local MODE_iAsBx = 2
local MODE_iAB   = 3

-- TODO: If we pack entire LuaXen into single file,
-- this code will result to an error, because the packer
-- wouldn't be able to find the files. We need to fix this.
local INSTRUCTIONS_FILE        = "Obfuscator/IronBrikked/Instructions/Instructions.lua"
local OBFUSCATOR_TEMPLATE_FILE = "Obfuscator/IronBrikked/ObfuscationTemplate.lua"
local MINIFIER_DEFAULT_CONFIG  = {
  uniqueNames             = false,
  replacableNames         = false,
  shouldLocalizeConstants = false,
  useGlobalsForConstants  = false,
  constantReuseThreshold  = 9e9
}

--* Local functions *--
local function generateOpcodeTree(opcodes, start, stop)
  if start > stop then
    return { opcodes[start] }
  end

  -- Calculate the midpoint of the opcode range
  local mid = floor((start + stop) / 2)

  -- Create a new node for the current opcode
  local node = {
    opcode = mid,
    left = generateOpcodeTree(opcodes, start, mid - 1),
    right = generateOpcodeTree(opcodes, mid + 1, stop)
  }

  return node
end


--* IronBrikked *--
local IronBrikkedMethods = {}

function IronBrikkedMethods:encodeProto(proto)
  local TYPE_DOUBLE = 0
  local TYPE_STRING = 1
  local TYPE_BOOLEAN = 3

  local instructions = proto.instructions
  local constants = proto.constants
  local numParams = proto.numParams or 0
  local prototypes = proto.protos

  -- Numbers
  local encodedNumConstants = writeFourBytes(#constants)
  local encodedNumInstructions = writeFourBytes(#instructions)
  local encodedNumParams = writeOneByte(numParams)
  local encodedNumPrototypes = writeFourBytes(#prototypes)

  -- Constants
  local encodedConstants = {}
  for i, constantValue in ipairs(constants) do
    local constantType
    if type(constantValue) == "boolean" then
      local boolean = writeOneByte(constantValue and 1 or 0)
      encodedConstants[i] = writeOneByte(TYPE_DOUBLE) .. boolean
    elseif type(constantValue) == "number" then
      local double = writeDouble(constantValue)
      encodedConstants[i] = writeOneByte(TYPE_DOUBLE) .. double
    elseif type(constantValue) == "string" then
      local string = writeString(constantValue)
      encodedConstants[i] = writeOneByte(TYPE_STRING) .. string
    end
  end

  -- Instructions
  local encodedInstructions = {}
  for i, instruction in ipairs(instructions) do
    local opname, a, b, c = instruction[1], instruction[2] or 0, instruction[3] or 0, instruction[4] or 0
    local opmode = opmodes[opcodeToNumberLookup[opname]]

    if supersetInstructions[opname] then
      -- Negative values for constants are not allowed
      -- So lets convert them to two complement form
      local aString = "A"
      local bString = (b >= 0 and "RB") or "KB"
      local cString = (c >= 0 and "RC") or "KC"
      local operandsForSuperInstruction = aString .. bString .. cString
      local superInstructionOPName = opname .. "_" .. operandsForSuperInstruction
      local isSuperInstruction = opcodeToNumberLookup[superInstructionOPName] ~= nil
      if not isSuperInstruction then
        error("Invalid super instruction: " .. superInstructionOPName)
      end

      a = abs(a)
      b = abs(b)
      c = abs(c)
      opname = superInstructionOPName
    else
      a = (a < 0 and 256 - a) or a
      b = (b < 0 and 256 - b) or b
      c = (c < 0 and 256 - c) or c
    end

    if opmode == MODE_iABC then
      encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(opcodeToNumberLookup[opname])
                                .. writeTwoBytes(a) -- A
                                .. writeTwoBytes(b) -- B
                                .. writeTwoBytes(c) -- C
    elseif opmode == MODE_iABx then
      encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(opcodeToNumberLookup[opname])
                                .. writeTwoBytes(a)          -- A
                                .. writeFourBytes(b + 65536) -- Bx
    elseif opmode == MODE_iAsBx then
      encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(opcodeToNumberLookup[opname])
                                .. writeTwoBytes(a)          -- A
                                .. writeFourBytes(b + 65536) -- sBx
    end
  end

  -- Prototypes
  local encodedPrototypes = {}
  for i, prototype in ipairs(prototypes) do
    encodedPrototypes[i] = self:encodeProto(prototype)
  end

  return   encodedNumConstants    .. concat(encodedConstants)
        .. encodedNumInstructions .. concat(encodedInstructions)
        .. encodedNumParams
        .. encodedNumPrototypes   .. concat(encodedPrototypes)
end

function IronBrikkedMethods:encodeProtoAndConvertToAST(proto)
  local encodedProto = lzwCompress(self:encodeProto(proto))
  local instructionsAST = Parser:new(Lexer:new(readFile(INSTRUCTIONS_FILE)):tokenize(), false):parse()
  local obfuscatorAST = Parser:new(Lexer:new(readFile(OBFUSCATOR_TEMPLATE_FILE)):tokenize(), false):parse()
  return encodedProto, instructionsAST, obfuscatorAST
end

function IronBrikkedMethods:findVmHandlerLoopAndProtoStringNode(obfuscatorAST)
  local vmHandlerLoop, protoStringNode
  ASTWalker.traverseAST(obfuscatorAST, function(node)
    return node.TYPE == "UntilLoop"
  end, function(node) vmHandlerLoop = node end)

  protoStringNode = obfuscatorAST[1].Expressions[1].Value.Arguments[1].Value
  return vmHandlerLoop, protoStringNode
end

function IronBrikkedMethods:getInstructionsImplementations(instructionsAST)
  local instructionsImplementations = {}
  for index, node in ipairs(instructionsAST) do
    assert(node.TYPE == "LocalFunction", "Detected a non-function node in the instructions")
    local name = node.Name
    local codeblock = node.CodeBlock
    instructionsImplementations[opcodeToNumberLookup[name]] = { Name = name, CodeBlock = codeblock }
  end
  return instructionsImplementations
end

function IronBrikkedMethods:createIfStatement(instructionsImplementations)
  local opcodeTree = generateOpcodeTree(instructionsImplementations, 0, #instructionsImplementations)
  local function placeIfStatement(node)
    if not node then return end
    if not node.opcode then
      if not node[1] then
        return
      end
      return node[1].CodeBlock
    end

    local opcode = node.opcode
    local ifStatement = createIfStatementNode(
      createOperatorNode("<=", createLocalVariableNode("opcode"), createNumberNode(opcode)),
      { placeIfStatement(node.left) },
      {}
    )
    ifStatement.Else = createElseStatementNode({node.right and placeIfStatement(node.right)})
    return ifStatement
  end

  return placeIfStatement(opcodeTree)
end

function IronBrikkedMethods:obfuscate()
  local proto = self.proto
  local encodedProto, instructionsAST, obfuscatorAST = self:encodeProtoAndConvertToAST(proto)
  local vmHandlerLoop, protoStringNode = self:findVmHandlerLoopAndProtoStringNode(obfuscatorAST)
  protoStringNode.Value = encodedProto

  local instructionsImplementations = self:getInstructionsImplementations(instructionsAST)

  local ifStatement = self:createIfStatement(instructionsImplementations)
  insert(vmHandlerLoop.CodeBlock, 2, ifStatement)

  -- Stage 1: Generate an AST
  local tokens = ASTToTokensConverter:new(obfuscatorAST):convert()
  local code1 = Printer:new(tokens):run()
  local ast2 = LuaInterpreter.ConvertScriptToAST(code1)

  -- Stage 2: Obfuscate variable names using the Minifier
  Minifier:new(ast2, MINIFIER_DEFAULT_CONFIG):minify()
  local astTokens2 = ASTToTokensConverter:new(ast2):convert()
  local code2 = Printer:new(astTokens2):run()

  return code2
end

--* IronBrikked *--
local IronBrikked = {}
function IronBrikked:new(proto)
  local IronBrikkedInstance = {}
  IronBrikkedInstance.proto = proto

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if IronBrikkedInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and IronBrikkedInstance: " .. index)
      end
      IronBrikkedInstance[index] = value
    end
  end

  -- Main
  inheritModule("IronBrikkedMethods", IronBrikkedMethods)

  return IronBrikkedInstance
end

return IronBrikked