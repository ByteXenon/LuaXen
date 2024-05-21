--[[
  Name: Main.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
--]]

-- This is the backend of the obfuscator
-- This script will not be placed in final obfuscated code

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Crypt = require("Crypt/Crypt")
local Minifier = require("Minifier/Minifier")
local Printer = require("Printer/Printer")
local ASTPrinter = require("Printer/ASTPrinter/ASTPrinter")
local ASTWalker = require("ASTWalker/ASTWalker")

local LuaInterpreter = require("Interpreter/LuaInterpreter/LuaInterpreter")

local Lexer = LuaInterpreter.modules.Lexer
local Parser = LuaInterpreter.modules.Parser
local ASTToTokensConverter = LuaInterpreter.modules.ASTToTokensConverter
local NodeFactory = LuaInterpreter.modules.NodeFactory

--* Imports *--
local insert = table.insert
local concat = table.concat
local floor = math.floor
local abs = math.abs
local char = string.char
local sub = string.sub

local readFile = Helpers.readFile

local createIfStatementNode = NodeFactory.createIfStatementNode
local createElseIfStatementNode = NodeFactory.createElseIfStatementNode
local createElseStatementNode = NodeFactory.createElseStatementNode
local createOperatorNode = NodeFactory.createOperatorNode
local createLocalVariableNode = NodeFactory.createLocalVariableNode
local createNumberNode = NodeFactory.createNumberNode

local writeOneByte   = Crypt.Binary.makeOneByteLittleEndian
local writeTwoBytes  = Crypt.Binary.makeTwoBytesLittleEndian
local writeFourBytes = Crypt.Binary.makeFourBytesLittleEndian
local writeDouble    = Crypt.Binary.makeDoubleLittleEndian
local writeString    = Crypt.Binary.makeStringLittleEndian
local toBase36 = Crypt.Conversion.toBase36

--* Constants *--
local INSTRUCTIONS_FILE = "Obfuscator/IronBrikked/templates/2701/Instructions/Instructions.lua"
local OBFUSCATOR_FILE = "Obfuscator/IronBrikked/templates/2701/0.lua"
local MINIFIER_DEFAULT_CONFIG = {
  uniqueNames = false,
  replacableNames = false,
  shouldLocalizeConstants = false,
  constantReuseThreshold = 9e9,
  useGlobalsForConstants = false
}

-- snippets
local INSTRUCTION_ASSIGNMENT = "local instruction, opcode = instructions[pc], instructions[pc][1]"
local INVALID_OPCODE_ERROR = [[error("Invalid opcode: " .. tostring(opcode))]]

-- nodes
local INSTRUCTION_ASSIGNMENT_NODE = Parser:new(Lexer:new(INSTRUCTION_ASSIGNMENT):tokenize(), false):parse()[1]
local INVALID_OPCODE_ERROR_NODE = Parser:new(Lexer:new(INVALID_OPCODE_ERROR):tokenize(), false):parse()[1]

local MODE_iABC = 0
local MODE_iABx = 1
local MODE_iAsBx = 2
local MODE_iAB = 3

local OPCODE_TO_NUMBER = {
  ["MOVE"]     = 0,  ["LOADK"]     = 1,  ["LOADBOOL"] = 2,  ["LOADNIL"]   = 3,
  ["GETUPVAL"] = 4,  ["GETGLOBAL"] = 5,  ["GETTABLE"] = 6,  ["SETGLOBAL"] = 7,
  ["SETUPVAL"] = 8,  ["SETTABLE"]  = 9,  ["NEWTABLE"] = 10, ["SELF"]      = 11,
  ["ADD"]      = 12, ["SUB"]       = 13, ["MUL"]      = 14, ["DIV"]       = 15,
  ["MOD"]      = 16, ["POW"]       = 17, ["UNM"]      = 18, ["NOT"]       = 19,
  ["LEN"]      = 20, ["CONCAT"]    = 21, ["JMP"]      = 22, ["EQ"]        = 23,
  ["LT"]       = 24, ["LE"]        = 25, ["TEST"]     = 26, ["TESTSET"]   = 27,
  ["CALL"]     = 28, ["TAILCALL"]  = 29, ["RETURN"]   = 30, ["FORLOOP"]   = 31,
  ["FORPREP"]  = 32, ["TFORLOOP"]  = 33, ["SETLIST"]  = 34, ["CLOSE"]     = 35,
  ["CLOSURE"]  = 36, ["VARARG"]    = 37,

  -- SUPER INSTRUCTIONS

  -- Different opmodes superinstructions
  ["GETTABLE_AKBKC"] = 38, ["GETTABLE_AKBRC"] = 39, ["GETTABLE_ARBKC"] = 40, ["GETTABLE_ARBRC"] = 41,
  ["SETTABLE_AKBKC"] = 42, ["SETTABLE_AKBRC"] = 43, ["SETTABLE_ARBKC"] = 44, ["SETTABLE_ARBRC"] = 45,
  ["SELF_AKBKC"]     = 46, ["SELF_AKBRC"]     = 47, ["SELF_ARBKC"]     = 48, ["SELF_ARBRC"]     = 49,
  ["ADD_AKBKC"]      = 50, ["ADD_AKBRC"]      = 51, ["ADD_ARBKC"]      = 52, ["ADD_ARBRC"]      = 53,
  ["SUB_AKBKC"]      = 54, ["SUB_AKBRC"]      = 55, ["SUB_ARBKC"]      = 56, ["SUB_ARBRC"]      = 57,
  ["MUL_AKBKC"]      = 58, ["MUL_AKBRC"]      = 59, ["MUL_ARBKC"]      = 60, ["MUL_ARBRC"]      = 61,
  ["DIV_AKBKC"]      = 62, ["DIV_AKBRC"]      = 63, ["DIV_ARBKC"]      = 64, ["DIV_ARBRC"]      = 65,
  ["MOD_AKBKC"]      = 66, ["MOD_AKBRC"]      = 67, ["MOD_ARBKC"]      = 68, ["MOD_ARBRC"]      = 69,
  ["POW_AKBKC"]      = 70, ["POW_AKBRC"]      = 71, ["POW_ARBKC"]      = 72, ["POW_ARBRC"]      = 73,
  ["EQ_AKBKC"]       = 74, ["EQ_AKBRC"]       = 75, ["EQ_ARBKC"]       = 76, ["EQ_ARBRC"]       = 77,
  ["LT_AKBKC"]       = 78, ["LT_AKBRC"]       = 79, ["LT_ARBKC"]       = 80, ["LT_ARBRC"]       = 81,
  ["LE_AKBKC"]       = 82, ["LE_AKBRC"]       = 83, ["LE_ARBKC"]       = 84, ["LE_ARBRC"]       = 85,
}

local REPLACE_INSTRUCTIONS_BY_SUPERINSTRUCTIONS = {
  ["GETTABLE"] = true,
  ["SETTABLE"] = true,
  ["SELF"] = true,
  ["ADD"] = true,
  ["SUB"] = true,
  ["MUL"] = true,
  ["DIV"] = true,
  ["MOD"] = true,
  ["POW"] = true,
  ["EQ"] = true,
  ["LT"] = true,
  ["LE"] = true
}

local OPMODES = {
  [0] = MODE_iABC,  [1]  = MODE_iABx,  [2]  = MODE_iABC,
  [3] = MODE_iABC,  [4]  = MODE_iABC,  [5]  = MODE_iABx,
  [6] = MODE_iABC,  [7]  = MODE_iABx,  [8]  = MODE_iABC,
  [9] = MODE_iABC,  [10] = MODE_iABC,  [11] = MODE_iABC,
  [12] = MODE_iABC, [13] = MODE_iABC,  [14] = MODE_iABC,
  [15] = MODE_iABC, [16] = MODE_iABC,  [17] = MODE_iABC,
  [18] = MODE_iABC, [19] = MODE_iABC,  [20] = MODE_iABC,
  [21] = MODE_iABC, [22] = MODE_iAsBx, [23] = MODE_iABC,
  [24] = MODE_iABC, [25] = MODE_iABC,  [26] = MODE_iABC,
  [27] = MODE_iABC, [28] = MODE_iABC,  [29] = MODE_iABC,
  [30] = MODE_iABC, [31] = MODE_iAsBx, [32] = MODE_iAsBx,
  [33] = MODE_iABC, [34] = MODE_iABC,  [35] = MODE_iABC,
  [36] = MODE_iABx, [37] = MODE_iABC
}

--* Local functions *--
local function deepCopyTable(tb)
  local copy = {}
  for index, value in pairs(tb) do
    if type(value) == "table" then
      copy[index] = deepCopyTable(value)
    else
      copy[index] = value
    end
  end
  return copy
end

--* Main *--
local Main = {}

function Main.encodeString(inputString)
  local dictionarySize = 256
  local dictionary = {}
  for i = 0, dictionarySize - 1 do
    dictionary[char(i)] = i
  end

  local currentChar = sub(inputString, 1, 1)
  local nextChar = ""
  local output = {}
  for i = 2, #inputString do
    nextChar = sub(inputString, i, i)
    if not dictionary[currentChar .. nextChar] then
      local code = dictionary[currentChar]
      insert(output, toBase36(#toBase36(code)))
      insert(output, toBase36(code))
      dictionary[currentChar .. nextChar] = dictionarySize
      currentChar = nextChar
      dictionarySize = dictionarySize + 1
    else
      currentChar = currentChar .. nextChar
    end
  end
  if currentChar ~= "" then
    local code = dictionary[currentChar]
    local codeLength = #toBase36(code)
    insert(output, toBase36(codeLength))
    insert(output, toBase36(code))
  end

  return concat(output)
end

function Main.encodeProto(proto)
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
    local opmode = OPMODES[OPCODE_TO_NUMBER[opname]]

    if REPLACE_INSTRUCTIONS_BY_SUPERINSTRUCTIONS[opname] then
      -- Negative values for constants are not allowed
      -- So lets convert them to two complement form
      local aString = "A"
      local bString = (b >= 0 and "RB") or "KB"
      local cString = (c >= 0 and "RC") or "KC"
      local operandsForSuperInstruction = aString .. bString .. cString
      local superInstructionOPName = opname .. "_" .. operandsForSuperInstruction
      local isSuperInstruction = OPCODE_TO_NUMBER[superInstructionOPName] ~= nil
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
                                .. writeOneByte(OPCODE_TO_NUMBER[opname])
                                .. writeTwoBytes(a) -- A
                                .. writeTwoBytes(b) -- B
                                .. writeTwoBytes(c) -- C
    elseif opmode == MODE_iABx then
      encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(OPCODE_TO_NUMBER[opname])
                                .. writeTwoBytes(a)  -- A
                                .. writeFourBytes(b + 65536) -- Bx
    elseif opmode == MODE_iAsBx then
      encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(OPCODE_TO_NUMBER[opname])
                                .. writeTwoBytes(a)  -- A
                                .. writeFourBytes(b + 65536) -- sBx
    elseif opmode == MODE_iAB then
      error("Not used")
      --[[encodedInstructions[i] =     writeOneByte(opmode)
                                .. writeOneByte(OPCODE_TO_NUMBER[opname])
                                .. writeTwoBytes(a) -- A
                                .. writeTwoBytes(b) -- B
      --]]
    end
  end

  -- Prototypes
  local encodedPrototypes = {}
  for i, prototype in ipairs(prototypes) do
    encodedPrototypes[i] = Main.encodeProto(prototype)
  end

  return   encodedNumConstants    .. concat(encodedConstants)
        .. encodedNumInstructions .. concat(encodedInstructions)
        .. encodedNumParams
        .. encodedNumPrototypes   .. concat(encodedPrototypes)
end

function Main.encodeProtoAndConvertToAST(proto)
  local encodedProto = Main.encodeString(Main.encodeProto(proto))
  local instructionsAST = Parser:new(Lexer:new(readFile(INSTRUCTIONS_FILE)):tokenize(), false):parse()
  local obfuscatorAST = Parser:new(Lexer:new(readFile(OBFUSCATOR_FILE)):tokenize(), false):parse()
  return encodedProto, instructionsAST, obfuscatorAST
end

function Main.findVmHandlerLoopAndProtoStringNode(obfuscatorAST)
  local vmHandlerLoop, protoStringNode
  ASTWalker.traverseAST(obfuscatorAST, function(node)
    if vmHandlerLoop then
      --error("Please, don't place other repeat-until loops in the obfuscator file")
    end

    return node.TYPE == "UntilLoop"
  end, function(node) vmHandlerLoop = node end)

  protoStringNode = obfuscatorAST[1].Expressions[1].Value.Arguments[1].Value
  return vmHandlerLoop, protoStringNode
end

function Main.getInstructionsImplementations(instructionsAST)
  local instructionsImplementations = {}
  for index, node in ipairs(instructionsAST) do
    assert(node.TYPE == "LocalFunction", "Detected a non-function node in the instructions")
    local name = node.Name
    local codeblock = node.CodeBlock
    instructionsImplementations[OPCODE_TO_NUMBER[name]] = { Name = name, CodeBlock = codeblock }
  end
  return instructionsImplementations
end

function Main.generateOpcodeTree(opcodes, start, stop)
  -- Base case: if the start index is greater than the stop index, return an empty table
  if start > stop then
    return { opcodes[start] }
  end

  -- Calculate the midpoint of the opcode range
  local mid = floor((start + stop) / 2)

  -- Create a new node for the current opcode
  local node = {
    opcode = mid,
    left = Main.generateOpcodeTree(opcodes, start, mid - 1),
    right = Main.generateOpcodeTree(opcodes, mid + 1, stop)
  }

  return node
end

function Main.createIfStatement(instructionsImplementations)
  local opcodeTree = Main.generateOpcodeTree(instructionsImplementations, 0, #instructionsImplementations)
  local function recursive(node)
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
      { recursive(node.left) },
      {}
    )
    --i--f node.right and node.right.opcode then
    ifStatement.Else = createElseStatementNode({node.right and recursive(node.right)})
    --end
    return ifStatement
  end

  return recursive(opcodeTree)
end

function Main.obfuscate(proto)
  local encodedProto, instructionsAST, obfuscatorAST = Main.encodeProtoAndConvertToAST(proto)
  local vmHandlerLoop, protoStringNode = Main.findVmHandlerLoopAndProtoStringNode(obfuscatorAST)
  insert(vmHandlerLoop.CodeBlock, 1, deepCopyTable(INSTRUCTION_ASSIGNMENT_NODE))

  local instructionsImplementations = Main.getInstructionsImplementations(instructionsAST)
  local ifStatement = Main.createIfStatement(instructionsImplementations)
  protoStringNode.Value = encodedProto
  insert(vmHandlerLoop.CodeBlock, 2, ifStatement)
  local tokens = ASTToTokensConverter:new(obfuscatorAST):convert()
  local code1 = Printer:new(tokens):run()
  -- print(code1)

  local ast2 = LuaInterpreter.ConvertScriptToAST(code1)
  -- print(ASTPrinter:new(ast2):print())
  Minifier:new(ast2, MINIFIER_DEFAULT_CONFIG):minify()
  local astTokens2 = ASTToTokensConverter:new(ast2):convert()
  local code2 = Printer:new(astTokens2):run()
  return code2
end

return Main