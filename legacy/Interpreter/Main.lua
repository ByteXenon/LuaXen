--[[
  Name: Main.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/05/XX
--]]

--  * Libraries * --
local Helpers = require("Helpers/Helpers")
local OPCodes = require("OPCodes/Main")

--* Preindex functions for performance *--
local Find = (table.find or Helpers.TableFind)
local Insert = (table.insert)

--* Interpreter object *--
local Interpreter = {}

--* Functions *--
function Interpreter.Interpreter(Input)
	-- TODO:
	--     Change the variable names to more
	--     obvious, better ones.
	--
	--     Add more OOP, it's hard to know
	--     which variables are needed for
	--     each purpose
	local Parser = {}

	-- Initstalize required variables.
	function Parser.Init(Code)
		Parser.CharStream = Helpers.StringToTable(Code)
		Parser.CharPos = 1
		Parser.CurChar = Parser.CharStream[1]
	end
	-- Jump to next or n'th character from current position
	function Parser.LookAhead(n)
		Parser.CharPos = (Parser.CharPos + (n or 1))
		Parser.CurChar = Parser.CharStream[Parser.CharPos]
		return Parser.CurChar
	end
	-- Get next or n'th character from the current position.
	-- If len is present it will return string with length of "n".
	-- (This function does not jump)
	function Parser.ReadAhead(n, len)
		n = (n or 1)
		if len then
			local Table = {}
			for Pos = Parser.CharPos + n, Parser.CharPos + n + len do
				table.insert(Table, Parser.CharStream[Pos])
			end
			return table.concat(Table, "")
		end
		return Parser.CharStream[Parser.CharPos + n]
	end

	-- Match current character with characters in arguments,
	-- if the character is matched, return it.
	function Parser.Consume(...)
		local CurChar = Parser.CurChar
		for Index, Char in pairs({...}) do
			if Char == CurChar then
				return CurChar
			end
		end
	end
	-- Check if characters from the stream look like a number
	function Parser.IsNumber()
		return Parser.CurChar:match("%d") or (Parser.CurChar == "." and Parser.ReadAhead():match("%d"))
	end
	-- Check if characters from the stream look like a comment
	function Parser.IsComment()
		return Parser.CurChar == "-" and Parser.ReadAhead() == "-"
	end
	
	-- Check if characters from the stream are a whitespace/tab/newline characters.
	--/* There's shouldn't be ``if not IsBlank(Char) then return false end``,
  --/* so we dont need to call peek() each time we call Blank(),
  --/* just assume that we already know that the first character
  --/* is blank.
	function Parser.IsBlank(Char)
		local Char = Char or Parser.CurChar
		return (Char == " " or Char == "\t" or Char == "\n")
	end
	
	function Parser.IsFunction()
		return (Parser.ReadAhead(0, 7) == "function")
	end

	-- Check if characters from the stream look like a string
	function Parser.IsString()
		local NextChar = Parser.ReadAhead()
		local CurChar = Parser.CurChar
		return (CurChar == "'" or CurChar == '"') or (CurChar == "[" and (NextChar == "[" or NextChar == "="))
	end
	-- Check if characters from the stream look like a variable/reserved keyword.
	function Parser.IsIdentifier()
		return Parser.CurChar:match("%a")
	end

	-- * READ BLOCK * --
	-- 
	--    These are functions that read various syntax objects.
	--    most, if not all, stop at the last character,
	--    so if you need to read a number you need LookAhead()
	--    after calling this function, otherwise it would be
	--    two numbers (or even infinite recursion!), which is wrong.
	--

	-- Consume/Read a number.
	function Parser.ReadNumber()
		-- Add floating point and scientific notation
		-- variables so we can look if there's already
		-- were these characters and throw an error.
		local FloatingPoint = (Parser.CurChar == ".")
		local ScientificNotation = false

		-- Use table instead of string so it's faster.
		local NewNumber = { Parser.CurChar }
 		local NewNumberIndex = 2;

		local ReturnResult;
		function ReturnResult()
			return table.concat(NewNumber, "")
		end

		local LastChar = Parser.CurChar

		-- In Lua numbers may start on floating point.
		if Parser.CurChar == "." or Parser.CurChar:match("%d") then
			while ( Parser.ReadAhead() and (Parser.ReadAhead():match("%d") or Parser.ReadAhead() == ".") and Parser.LookAhead()) do
				if Parser.CurChar == "." then
					assert(not FloatingPoint, "Syntax error, malformed number")
					FloatingPoint = false
				end
				NewNumber[NewNumberIndex] = Parser.CurChar
				NewNumberIndex = NewNumberIndex + 1
			end
		end
		return ReturnResult()
	end
	
	function Parser.ReadComment()
		assert(Parser.IsComment(), "")
		Parser.LookAhead(2)

		if Parser.CurChar == "[" and (Parser.ReadAhead() == "[" or Parser.ReadAhead() == "=") then
			Parser.ReadComplexString()
		else
			while Parser.CurChar ~= "\n" do Parser.LookAhead() end
		end
		return true
	end
	
	-- < not IsAnonymous and < function <identf>[\.<identf>]*(<arg>?[,<arg>]*) <codeblock> end > > OR
	-- < IsAnonymous and < function(<arg>?[,<arg>]*) <codeblock> end > > 
	function Parser.ReadFunction(IsAnonymous)
		assert(Parser.IsFunction(), "")
		-- Skip "function" reserved keyword
		Parser.LookAhead(8);

		-- Find the name for non-anonymous functions
		local FunctionName
		if not IsAnonymous then
			Parser.ReadBlank()
			assert(Parser.IsIdentifier(), "expected <name>, got: " .. Parser.CurChar)
			FunctionName = Parser.ReadIdentifier()
			Parser.LookAhead()
		end
		-- Every function declaration in Lua must include parentheses for arguments 
		assert(Parser.CurChar == "(" or (Parser.ReadBlank() and Parser.CurChar == "("), "'(' Expected near 'function'")
		assert(Parser.LookAhead(1), "")
		Parser.ReadBlank()
		
		local Arguments = {}

		-- Make a function to read arguments
		local ReadArguments;
		function ReadArguments()
			local IsIdentifier = Parser.IsIdentifier() or (Parser.ReadBlank(nil, true) and Parser.IsIdentifier())
			assert(IsIdentifier, "")
			local NewKeyword = Parser.ReadIdentifier()
			table.insert(Arguments, NewKeyword)
			Parser.LookAhead(); Parser.ReadBlank(nil, true)
			
			if Parser.CurChar == "," and Parser.LookAhead() then
				return ReadArguments();
			elseif Parser.CurChar == ")" then
				return Arguments
			else
				error("Invalid character")
			end
		end
		local Arguments = (Parser.CurChar ~= ")" and ReadArguments()) or {}
		assert(Parser.LookAhead())
		local CodeBlock = Parser.CodeBlockHandler({ "end" })

		return {
			TYPE = "FUNCTION", 
			CodeBlock = CodeBlock, 
			Arguments = Arguments, 
			Name = FunctionName
		}
	end

	-- Check if current character looks like a variable, if so, increase
	-- the character counter until the next character is not a variable name
	function Parser.ReadIdentifier()
		assert(Parser.CurChar, "")
		if not Parser.CurChar:match("%a") then return false end

		-- local NewKeyword = Char
		-- It's better to use table.concat
		-- we use concat() only once, instead of
		-- n times (insert() is faster than concat) 
		local NewKeyword = {Parser.CurChar}
		local KeywordIndex = 2
		while Parser.ReadAhead() and Parser.ReadAhead():match("[%a%d_]") and Parser.LookAhead() do
			NewKeyword[KeywordIndex] = Parser.CurChar
			KeywordIndex = KeywordIndex + 1
		end
		return table.concat(NewKeyword, "")
	end

	-- Read simple strings, like these: "hello", 'hello'
	function Parser.ReadSimpleString()
		local OpenningChar = Parser.CurChar
		local NewString = {}
		local NewStringIndex = 1;

		local Escaped = false
		while Parser.LookAhead() do
			if (Parser.CurChar ~= "\\") or (Parser.CurChar == "\\" and Escaped) then
				if Parser.CurChar == "\n" and not Escaped then
					error("unfinished string")
				elseif Parser.CurChar == OpenningChar and not Escaped then
					return table.concat(NewString, "")
				end
				Escaped = false

				NewString[NewStringIndex] = Parser.CurChar
				NewStringIndex = NewStringIndex + 1
			else
				Escaped = not Escaped
			end
		end
		return error("Unexpected end of string")
	end

	-- Read multi-line complex strings, like these: [==[ hello ]==]
	function Parser.ReadComplexString()
		local NewString = {}
		local NewStringIndex = 1

		local CheckDepth, ReturnNewString

		function CheckDepth(StartIndex)
			local Depth = 0;

			if not StartIndex then
				while (Parser.ReadAhead() == "=" and Parser.LookAhead()) do
					Depth = Depth + 1
				end
			else
				while (Parser.ReadAhead(StartIndex + Depth) == "=") do
					Depth = Depth + 1
				end
			end

			return Depth
		end
		function ReturnString()
			return table.concat(NewString, "")
		end

		local CurrentDepth = CheckDepth();
		assert(Parser.LookAhead() == "[", ("[ Expected, got: %s"):format(Parser.CurChar))
			
		while Parser.LookAhead() do
			if Parser.CurChar == "]" then
				if CurrentDepth == 0 and Parser.ReadAhead() == "]" then
					Parser.LookAhead(1)
					return ReturnString()	
				elseif CurrentDepth ~= 0 and Parser.ReadAhead() == "=" then
					local NewDepth = CheckDepth(1)
					if ( NewDepth == CurrentDepth ) and
					   ( Parser.ReadAhead(NewDepth + 1) == "]"  ) then
						Parser.LookAhead(NewDepth + 1)
						return ReturnString()
					else
					end
				end
				
			end
			NewString[NewStringIndex] = Parser.CurChar
			NewStringIndex = NewStringIndex + 1
		end 

		return error("unfinished string")
	end

	-- A compability layer function for strings of all types
	-- It does nothing other than calling the right function for right string type
	function Parser.ReadString()
		if ( Parser.CurChar == '"' or Parser.CurChar == "'" ) then
			return Parser.ReadSimpleString()
		elseif Parser.CurChar == "[" and ( Parser.ReadAhead() == "[" or Parser.ReadAhead() == "=" ) then
			return Parser.ReadComplexString()
		else
			return error(("String expected, got: %s"):format(Parser.CurChar))
		end
	end


	function Parser.TokenizeExpression(BreakKeywords, JumpAfterBreak)
		local BreakKeywords = BreakKeywords or {}
		
		-- TODO: Make more flexible, for example make
		-- it easy to match more than 2 character operators.
		local OperatorTable = {
			--/ Logical operators \--
			["not"] = "NOT",
			["and"] = "AND",
			["or"] = "OR",
	
			--/ Comparison operators \--
			["!="] = "NOT_EQUAL",
			["=="] = "EQUAL_EQUAL",
			[">="] = "GREATER_EQUAL",
			["<="] = "LESS_EQUAL",
			[">"] = "GREATER",
			["<"] = "LESS",
				
			--/ Normal operators \--
			["!"] = "NOT",
			["^"] = "POW",
			["/"] = "DIV",
			["*"] = "MUL",
			["-"] = "SUB",
			["+"] = "ADD",
		}; local IsOperator;

		local BooleanTable = {
			["false"] = "FALSE",
			["true"] = "TRUE",
			["nil"] = "NIL" -- Yep, nil is a boolean.
		}; local IsBoolean;

		-- Check if character sequence look like an operator.
		function IsOperator(Jump)
			local Operator = Helpers.TableIndexSearch(OperatorTable, Parser.CharStream, Parser.CharPos)
			if Operator then
				-- If Jump argument is present, then
				-- jump on #Operator - 1 positions
				-- else don't jump.
				Parser.LookAhead((Jump and #Operator - 1) or 0)
				return OperatorTable[Operator]
			end
		end
		-- Check if character sequence look like a boolean.
		function IsBoolean(Jump)
			local Boolean = Helpers.TableIndexSearch(BooleanTable, Parser.CharStream, Parser.CharPos)
			if Boolean then
				Parser.LookAhead((Jump and #Boolean - 1) or 0)
				return BooleanTable[Boolean]
			end
		end

		-- Check and read if there's an index or parentheses 
		-- after a token
		local function ReadIndexOrParen(Token)
			local ReadIndex, ReadBrackets, ReadParentheses, Main
			function ReadIndex()
				Parser.ReadBlank()
				while (Parser.ReadAhead() == ".") do
					assert(Parser.LookAhead(2), "")
					Parser.ReadBlank(nil, true)
					assert(Parser.IsIdentifier(), "")
					local Index = Parser.ReadIdentifier()
					Token = { TYPE = "INDEX", Value = Token, Index = Index }
				end
				return ReadBrackets()
			end
			function ReadBrackets()
				Parser.ReadBlank()
				while (Parser.ReadAhead() == "[") do
					assert(Parser.LookAhead(2), "")
					Token = { TYPE = "INDEX", Value = Token, Parser.ReadExpression() }
					assert(Parser.CurChar == "]", "")
				end
				return ReadParentheses()
			end
			function ReadParentheses()
				Parser.ReadBlank()
				while (Parser.ReadAhead() == "(") do
					assert(Parser.LookAhead(), "")
					local FunctionCall = Parser.ReadFunctionCall(Token)
					Token = FunctionCall
				end
				return Main()
			end
			function Main()
				if Parser.IsBlank(Parser.ReadAhead()) then Parser.LookAhead() end
				Parser.ReadBlank()
				if Parser.ReadAhead() == "(" or Parser.ReadAhead() == "." or Parser.ReadAhead() == "[" then
					return ReadIndex()
				else
					return Token
				end
			end
			return Main()
		end

		local Tokens = {}
		local function AddToken(...)
			return Insert(Tokens, ...)
		end

		local Depth = 1

		while Parser.CurChar do			
			if Parser.IsBlank() then
			elseif Parser.IsComment() then
				Parser.ReadComment()
			elseif IsOperator() then
				local CompleteOperator = IsOperator(true)
				AddToken({ TYPE="OPERATOR", SUBTYPE=CompleteOperator })
			elseif IsBoolean() then
				local Boolean = IsBoolean(true)
				AddToken({ TYPE="BOOLEAN", Boolean })
			elseif Parser.IsString() then
				AddToken({ TYPE = "STRING", Parser.ReadString() })
			elseif Parser.IsNumber() then
				AddToken({ TYPE="NUMBER", Parser.ReadNumber() })
			elseif Parser.IsFunction() then
				AddToken( Parser.ReadFunction(true) )
			elseif Parser.CurChar == "." and Parser.LookAhead() then
				assert(Parser.IsIdentifier() or (Parser.ReadBlank() and Parser.IsIdentifier()), "")
				local NextIndex = Parser.ReadIdentifier()
				AddToken({ TYPE="INDEX", NextIndex })
			elseif Parser.CurChar == "[" and Parser.LookAhead() then
				local LastToken = Tokens[#Tokens]
				if LastToken["TYPE"] == "VARIABLE" or LastToken["TYPE"] == "INDEX" then
					AddToken({ TYPE = "BRACKETS", Parser.ReadExpression() })
				else
					return error("")
				end
			elseif Parser.CurChar == "(" then
				local PreviousToken = Tokens[#Tokens]
				if (not PreviousToken) then
					assert(Parser.LookAhead(), "")
					local Token = { TYPE="PARENTS", Parser.ReadExpression() }
					AddToken(ReadIndexOrParen(Token))
				end	
			elseif Parser.CurChar == ")" or Parser.CurChar == "]" then
				break		
			elseif Parser.IsIdentifier() then
				local NewIdentifier = Parser.ReadIdentifier()

				if Find(BreakKeywords, NewIdentifier) then
					break
				elseif Parser.Keywords[NewIdentifier] then
					Parser.LookAhead(-#NewIdentifier)
					break
				else
					local LastToken = Tokens[#Tokens]
					if ( LastToken and LastToken["TYPE"] ~= "OPERATOR" and LastToken["TYPE"] ~= "INDEX"
					     and LastToken["TYPE"] ~= "FUNCTION_CALL" and LastToken["TYPE"] ~= "PAREN_START" and
					        LastToken["TYPE"] ~= "BRACKET_START") then
						Parser.LookAhead(-(#NewIdentifier))
						break
					end;
					local Token = { TYPE="VARIABLE", NewIdentifier }

					Token = ReadIndexOrParen(Token)
					AddToken(Token)
				end
			elseif Parser.CurChar == "," or Parser.CurChar == ";" then
				break
			else
				return error("Invalid character: "..tostring(Parser.CurChar))
			end
			if Depth < 1 then
				break
			end
			Parser.LookAhead()
		end
			
		AddToken({ TYPE="EOF" })
		return Tokens
	end

	function Parser.ReadExpression(BreakKeywords)
		-- Assign upvalues so it will be possible
		-- for functions to call themselves again,
		-- recursion, baby!
		local Equality, Expression, Comparison,
		      Term, Factor, Power, Unary, Index, Primary

		local Tokens;
		local CurrentToken
		local CanOptimize
		local TokenIndex = 1;

		local function Previous()
			return Tokens[TokenIndex - 1]
		end
		local function Peek()
			return Tokens[TokenIndex]
		end
		local function IsAtEnd()
			return Peek() == nil
		end
		local function Advance()
			if not IsAtEnd() then TokenIndex = TokenIndex + 1 end
			return Previous()
		end
		local function Check(Type)
			if not IsAtEnd() and Type then
				return Type == Peek()["TYPE"] or Type == Peek()["SUBTYPE"]
			end
		end
		local function Match(...)
			for i, v in pairs({...}) do
				if Check(v) then
					Advance()
					return true
				end
			end
			return false
		end
		local function NewExpression(...)
			return {
				TYPE="EXPRESSION",
				...
			}
		end

		function Expression()
			return Equality()
		end
		function Equality()
			local Expr = Comparison()

			while (Match("NOT_EQUAL", "EQUAL_EQUAL", "GREATER_EQUAL", "LESS_EQUAL", "LESS", "GREATER")) do
				local Operator = Previous()
				local Right = Comparison()
				Expr = NewExpression(Expr, Operator, Right)
			end
			return Expr
		end
		function Comparison()
			local Expr = Term()
			
			while (Match("GREATER", "GREATER_EQUAL", "LESS", "LESS_EQUAL")) do
				local Operator = Previous()
				local Right = Term()
				Expr = NewExpression(Expr, Operator, Right)
			end
			return Expr
		end
		function Term()
			local Expr = Factor()

			while (Match("SUB", "ADD")) do
				local Operator = Previous()
				local Right = Factor()
				Expr = NewExpression(Expr, Operator, Right)
			end
			return Expr
		end
		function Factor()
			local Expr = Power()

			while (Match("DIV", "MUL")) do
				local Operator = Previous()
				local Right = Power()
				Expr = NewExpression(Expr, Operator, Right)
			end
			return Expr
		end
		function Power()
			local Expr = Unary()

			while (Match("POW")) do
				local Operator = Previous()
				local Right = Unary()
				Expr = NewExpression(Expr, Operator, Right)
			end
			return Expr
		end
		function Unary()
			-- There's UNM instead of SUB
			if (Match("NOT", "AND", "OR", "SUB")) then		
				local Operator = Previous()
				local OperatorType = Operator["TYPE"]
				Operator["TYPE"] = (OperatorType == "SUB" and "UNM") or OperatorType
				
				local Left = Unary()
				return NewExpression(Left, Operator)
			end

			return Primary()
		end

		function Primary()
			if (Match("NUMBER", "STRING", "FUNCTION_CALL", "INDEX", "VARIABLE", "BOOLEAN", "FUNCTION")) then
				return Previous()
			elseif (Match("PARENTS")) then
				return Previous()
			elseif (Match("EOF")) then
				return nil;
			end
			return (error(
				("Primary() error, unexpected token: %s")
				:format(Helpers.ParseTable(Tokens[TokenIndex]))
			))
		end

		Tokens = Parser.TokenizeExpression(BreakKeywords);
		local ExpressionTree = Expression(Tokens);
		return ExpressionTree
	end

	function Parser.AssignVariable(VariableName)
		assert(Parser.LookAhead(), "Unexpected variable assignment end")
		Parser.ReadAhead(); Parser.ReadBlank(); Parser.ReadAhead()
		local NewExpression = Parser.ReadExpression()
		return {TYPE="VARIABLE_ASSIGMENT", Name=VariableName, Expression=NewExpression}
	end

	function Parser.ReadBlank(StartingPos, Skip)
		local IsBlank = Parser.IsBlank
		local LookAhead = Parser.LookAhead
		local ReadAhead = Parser.ReadAhead

		if StartingPos then
			if not IsBlank(ReadAhead(StartingPos)) then return false, 0 end
			local Index = 1 + StartingPos
			while IsBlank(ReadAhead(Index)) do Index = Index + 1 end
			if Skip then return LookAhead(Index - 1), Index end
			return ReadAhead(Index - 1), Index
		else
			local Index = 0
			if not IsBlank() then return false, Index end
			while (IsBlank(ReadAhead())) do Index = Index + 1; LookAhead() end
			if Skip then return LookAhead(), Index end
			return Parser.CurChar, Index
		end
	end

	function Parser.ReadFunctionCall(Value, ReturnValues)
		assert(Parser.LookAhead(), "Unexpected function call end")
		local Arguments = {}
		
		local ParseArguments;
		function ParseArguments()
			table.insert(Arguments, Parser.ReadExpression({ "," }))
			if (Parser.CurChar == "," and Parser.LookAhead()) then
				return ParseArguments()
			end
			return Arguments
		end

		local Arguments = (Parser.CurChar ~= ")" and ParseArguments()) or {}

		assert(Parser.CurChar == ")", "Unknown character sequence")
		return {
			TYPE = "FUNCTION_CALL",
			Value = Value,
			Arguments = Arguments,
			ReturnValues = ReturnValues or 0
		}
	end

	function Parser.ReadLocalVariable()
		local VariableName = Parser.ReadIdentifier()
		assert(VariableName, "Invalid variable name!")
		Parser.LookAhead(1); Parser.ReadBlank(); Parser.LookAhead(1)

		if Parser.CurChar == "=" then
			-- OK, this is not just a variable
			-- declaration, but and assigment too!
			Parser.LookAhead(1); Parser.ReadBlank(); Parser.LookAhead(1);
			local NewExpression = Parser.ReadExpression({})
			return { TYPE = "LOCAL_ASSIGMENT", Name = VariableName, Expression = NewExpression }
		elseif Parser.CurChar == "," then
			-- Multiple declaration (assigment)?
			--local NewVariable = LocalVariable()
			--
			-- return {TYPE = "MULTY_LOCAL_DECLARATION", Name = VariableName}
		end
		return { TYPE = "LOCAL_DECLARATION", Name = VariableName }
	end

	-- These table functions are just handlers or input validators, rather than actual
	-- parsers
	Parser.Keywords = {
		-- local <name> = <expr>
		["local"] = function()
			-- Probably useless because we already check complete keywords
			-- but what if someone does like this: ``local()`` what should
			-- we do?
			--assert(Parser.ReadBlank(), "No spaces after keyword 'local'")
			--assert(Parser.LookAhead(), "");
			return Parser.ReadLocalVariable()
			-- local VariableName = Keyword()
			-- assert(VariableName, "No variable name!")
			-- Peek(); Blank()
			-- assert(Char == "=", "No equal sign after variable")
			-- Peek(); Blank()
			-- 
			-- local NewExpression = Expression({})
			-- return {TYPE = "LOCAL_ASSIGMENT", Name = VariableName, Expression = NewExpression}
		end,
		-- do <codeblock> end
		["do"] = function()
			--  assert(Peek() and Blank(), "No spaces after keyword 'do'")
			local NewCodeBlock = Parser.CodeBlockHandler({ "end" })
			return { TYPE = "DO", CodeBlock = NewCodeBlock }
		end,
		-- if <expr> then <codeblock> end
		["if"] = function()
			-- assert(Peek() and Blank(), "No spaces after keyword 'if'")
			local NewExpression = Parser.ReadExpression({ "then" })
			assert(Parser.LookAhead() and NewExpression, "")
			local NewCodeBlock = Parser.CodeBlockHandler({ "end" })
			return { TYPE = "IF", Expression = NewExpression, CodeBlock = NewCodeBlock }
		end,
		-- repeat <codeblock> until <expr>
		["repeat"] = function()
			-- assert(Peek() and Blank(Char), "No spaces after keyword 'repeat'")
			local NewCodeBlock = Parser.CodeBlockHandler({ "until" })
			assert(Parser.LookAhead() and Parser.IsBlank(), "No value after keyword 'until'")
			local NewExpression = Parser.ReadExpression({})
			return { TYPE = "REPEAT", Expression = NewExpression, CodeBlock = NewCodeBlock }
		end,
		-- while <expr> do <codeblock> end
		["while"] = function()
			-- assert(Peek() and Blank(Char), "No spaces after keyword 'while'")
			local NewExpression = Parser.ReadExpression({ "do" });
		
			-- Parser.ReadBlank(nil, true);
			-- print(Parser.CurChar, Parser.ReadAhead(-1))
			-- assert(Parser.ReadIdentifier() == "do" and Parser.LookAhead(), "");
			assert(Parser.LookAhead(), "")
			local NewCodeBlock = Parser.CodeBlockHandler({ "end" })
			return { TYPE = "WHILE", Expression = NewExpression, CodeBlock = NewCodeBlock }
		end,
		-- < for <stment>[,<stment>]* in <expr> do <codeblock> end > ||
		-- < for <stment>=<expr>,<expr>[,<expr>]? do <codeblock> end >
		["for"] = function()
			-- assert(Peek() and Blank(), "No spaces after keyword 'for'")
			
		end
	}

	function Parser.ReadCodeBlock(Table, StopKeywords)
		local StopKeywords = StopKeywords or {}
		
		if Parser.IsBlank() then
		elseif Parser.IsComment() then Parser.ReadComment()
		elseif Parser.IsIdentifier() then
			local NewIdentifier = Parser.ReadIdentifier()
			if Find(StopKeywords, NewIdentifier) then
				return false
			elseif NewIdentifier == "end" then
				return error("Unexpected end")
			elseif Parser.Keywords[NewIdentifier] and Parser.LookAhead() then
				assert((Parser.ReadBlank(nil, true)), "")
				table.insert(Table, (Parser.Keywords[NewIdentifier])() )
			else
				if (Parser.LookAhead() == "(" or (Parser.ReadBlank() and Parser.CurChar == "(")) then
					table.insert(Table, Parser.ReadFunctionCall(NewIdentifier))
				elseif (Parser.CurChar == "=" and Parser.ReadAhead()) then
					table.insert(Table, Parser.AssignVariable(NewIdentifier))
				else
					print(NewIdentifier, #NewIdentifier)
					return error("Invalid character sequence")
				end
			end
		else
			table.insert(Table, Parser.ReadExpression())
		end
		return Table
	end

	function Parser.CodeBlockHandler(StopKeywords)
		local Table = {}
		while Parser.ReadCodeBlock(Table, StopKeywords) and Parser.LookAhead() do end
		return Table
	end

	Parser.Init(Input)
	return Parser.CodeBlockHandler()
end

return Interpreter
