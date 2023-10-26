--[[
  Name: example.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

local function Parser()
  local Parser = {}

  -- Initialize the parser
  function Parser.__init__(CharStream, CharPos, ErrorOnMismatch, ReturnTable, CustomFunctions)
      -- Store parser state
      Parser.CharStream = CharStream
      Parser.CharPos = CharPos or 1
      Parser.OldPosition = Parser.CharPos
      Parser.ErrorOnMismatch = ErrorOnMismatch ~= false
      Parser.ReturnTable = (ReturnTable or {})
      Parser.CurChar = CharStream[Parser.CharPos]        
      Parser.Status = true

      -- Assign custom functions if provided
      if CustomFunctions then
          for Index, Value in pairs(CustomFunctions) do
              Parser[Index] = Value
          end
      end

      return Parser
  end

  -- Initialize a shared parser with common values
  function Parser.__shared_init__(SharedParser, SharedValues)
      return Parser.__sync__(SharedParser, SharedValues)
  end

  -- Synchronize parser state with a shared parser
  function Parser.__sync__(SharedParser, SyncValues)
      local SyncValues = SyncValues or {
          "CurChar", "CharPos", "CharStream"
      }

      for _, Value in ipairs(SyncValues) do
          SharedParser[Index] = Parser[Index]
      end

      return Parser
  end

  -- Change parser options dynamically
  function Parser.ChangeOptions(Table)
      for Index, Value in pairs(Table) do
          Parser[Index] = Value
      end
  end

   -- Report an error in parsing
  function Parser.Error(Expected, Actual)
      if Parser.ErrorOnMismatch then
          Expected, Actual = tostring(Expected), tostring(Actual)
          return error(("Error, expected: '%s', got: '%s'"):format(Expected, Actual))
      end
      Parser.Status = false

      -- Disable parser functions to stop parsing
      for Index, Value in pairs(Parser) do
          if type(Value) == "function" then
              Parser[Index] = function() end
          end
      end
  end

  -- Peek the next character in the stream
  function Parser.PeekNext(n)
      Parser.CharPos = Parser.CharPos + (n or 1)
      Parser.CurChar = Parser.CharStream[Parser.CharPos]
      return Parser.CurChar
  end
  
  -- Read the next character in the stream
  function Parser.ReadNext(n)
      return Parser.CharStream[Parser.CharPos + (or 1)]
  end

  -- Parse a keyword from the stream
  function Parser.Keyword(Expected, Index, Table)
      local TargetTable = (Table or Parser.ReturnTable)
      local TargetIndex = (Index or #TargetTable)
      
      -- Check if the given character is a keyword character
      local function IsKeyword(Character)
          if not Character then return end
          return Character:match("[%a_]") 
      end

      -- Read and return the keyword from the stream
      local function ReadKeyword()
          if not IsKeyword() then return end

          local Keyword = { Parser.CurChar }
          while IsKeyword( Parser.PeekNext() ) do
              table.insert(Keyword, Parser.CurChar)
          end

          return table.concat(Keyword)
      end

      -- Parse the keyword and check if it matches the expected value
      local ActualKeyword = ReadKeyword()
      if Expected and Expected ~= ActualKeyword then
          return Parser.Error(Expected, ActualKeyword)
      end

      -- Save the keyword in the table if provided
      if (Index or Table) then
          TargetTable[TargetIndex] = ActualKeyword
      end
  end

  -- Parse a string from the stream
  function Parser.String(Expected, Index, Table)
      assert(String, "String required.")
  
      local TargetTable = (Table or Parser.ReturnTable)
      local TargetIndex = (Index or #TargetTable)
  
      -- Read and return the string from the stream
      local function ReadString(Expected)
          local NewString = {}
          local Index = 1

          while Expected[Index] and Parser.CurChar == Expected[Index] do
              table.insert(NewString, Parser.CurChar)
              Parser.PeekNext()
              Index = Index + 1
          end

          return table.concat(NewString)
      end

      -- Convert the expected string to a table and parse the string
      local ConvertedString = Helpers.StringToTable(Expected)
      local ActualString = ReadString(ConvertedString)
      
      -- Check if the parsed string matches the expected value 
      if Expected ~= ActualString then
          return Parser.Error(String, ActualString)
      end

      -- Save the string in the table if provided
      if (Index or Table) then
          Table[Index] = ActualString
      end
  end

  -- Parse blank characters
  function Parser.Blank(_, Index, Table)
      -- local TargetTable = Table or Parser.ReturnTable
      -- local TargetIndex = Index or #TargetTable

      -- Check if the given character is a blank
      local function IsBlank(Character)
          if not Character then return end
          return table.find({"\t", "\n", " "}, Character)
      end

      -- Skip all blank character until a non-blank character is found
      if IsBlank() and Parser.PeekNext() then
          while IsBlank(Parser.CurChar) do
              Parser.PeekNext()
          end
      else
          return Parser.Error("<blank>", Parser.CurChar)
      end
  end

  -- Parse an option based on a statement
  function Parser.Option(Table)
      local Statement = Table["Statement"]
      local Value1 = Table["Value1"]
      local Value2 = Table["Value2"]

      -- Create separate parsers for different branches
      local StatementParser = AAC.NewParser()
          .__shared_init__(Parser)
          .ChangeOptions( { ErrorOnMismatch = false } )
      local Value1Parser = AAC.NewParser()
          .__shared_init__(Parser)
      local Value2Parser = AAC.NewParser()
          .__shared_init__(Parser)

      Statement(StatementParser)
      
      -- Parse Value1 if the statement is successful
      if StatementParser.Status then
          Value1(Value1Parser)
          return Value1Parser.Status
      else
          -- Parse Value2 if the statement fails
          Value2(Value2Parser)
          return Value2Parser.Status
      end
  end

  -- Parse a loop statement
  function Parser.LOOP(ZeroOrMore, Statement, Value)
      local StatementParser = AAC.NewParser()
          .__shared_init__(Parser)
          .ChangeOptions( { ErrorOnMismatch = false } )

      local ValueParser = AAC.NewParser()
          .__shared_init__(Parser)

      -- Continue parsing the statement until it fails
      while Statement(StatementParser) do
          Value(ValueParser)
      end

      return ValueParser.Status
  end

  function Parser.IF(Statement, Value)
      local StatementParser = AAC.NewParser()
          .__shared_init__(Parser)
          .ChangeOptions( { ErrorOnMismatch = false } )

      local ValueParser = AAC.NewParser()
          .__shared_init__(Parser)

      -- Parse the statement and execute the value if it's true
      if Statement(StatementParser) then
          Value(ValueParser)
      end

      return ValueParser.Status
  end

  return Parser
end

local Parser = {}
function Parser:newSynthax(configuration)
    local ParserInstance = {}

    ParserInstance.oldPosition = self.curCharPos
    ParserInstance.charStream = self.charStream
    --ParserInstance.

    function ParserInstance:Keyword()

    end
    function ParserInstance:ZeroOrOne()

    end
    function ParserInstance:ZeroOrMore()

    end
    function ParserInstance:OneOrMore()

    end
end;

(function(self)
    self:__init__(nil, nil, nil)
    self:ZeroOrOne(
      ,function(self)
        self:Keyword(2)
        self:ZeroOrMore(
          ,function(self)
            self:Keyword(2)
            self:OneOrMore(
              ,function(self)
                self:Keyword(2)
                self:Keyword(3)
              end
              ,function(self)
                self:Keyword(1)
              end
            )
          end
          ,function(self)
            self:Keyword(1)
          end
        )
      end
      ,function(self)
        self:Keyword(1)
      end
    )
end)(Parser:newSynthax())