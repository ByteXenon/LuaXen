--[[
  Name: Main.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/05/XX
--]]

--* Libraries *--
local Helpers = require("Helpers/Helpers")
local OPCodes = require("OPCodes/Main")
local Visual = require("Visual/Main")

--* Preindex functions *--
local Find = (table.find or Helpers.TableFind)

--* Parser object *--
local Parser = {};

--* Functions *--
function Parser.GetInstructions(Tokens)
	-- TODO: -- Expressions in function calls ```print(1+2+3)``` --
	--       / Lua solves expressions in calls during interpretation
	--       so we don't get ADD instructions, 
	--       instead we get LOADK with "6" constant.
	--       We need to solve expressions at compile time.
	--
	--       Instead of cloning tables to reset local variables,
	--       we should use different states with functions that
	--       would share Constants, Instructions, Registers or Locals
	--       between each other.

	local CreateState;
	function CreateState()
		local NewState = {
			-- Ideally these tables should be private
			-- to set/get elements in these tables we
			-- should make functions
			Constants = {},
			Instructions = {},
			Locals = {},
			Registers = {},
			StackTopIndex = 0
		}

		function NewState.AppendInstruction(OPName, A, B, C, Flag)
			NewState.StackTopIndex = NewState.StackTopIndex + 1
			
			table.insert(NewState.Instructions, {OPName, A, B, C})
		end
		function NewState.NewInstruction(Index, OPName, A, B, C, Flag)
			NewState.Instructions[Index] = {OPName, A, B, C}
			return Index
		end
		function NewState.AllocateRegister(RegisterIndex)
			if not RegisterIndex then
				RegisterIndex = 0
				for i,v in pairs(NewState.Registers) do
					RegisterIndex = RegisterIndex + 1
				end
			end
			-- RegisterIndex = (RegisterIndex) or (State.StackTopIndex)
			NewState.Registers[RegisterIndex] = true
			return RegisterIndex, {
				DeallocateRegister = function()
					-- print(("Deallocated register: %d"):format(RegisterIndex))
					-- print(debug.traceback())
					NewState.Registers[RegisterIndex] = nil
				end
			}
		end
		function NewState.DeallocateRegister(RegisterIndex)
			RegisterIndex = RegisterIndex or #NewState.Registers
			NewState.Registers[RegisterIndex] = nil
			return RegisterIndex
		end

		-- Add/Remove/Find functions for locals
		function NewState.AddLocal(LocalName, RegisterIndex)
			local LocalObject = {
				Register = RegisterIndex
			}
			NewState.Locals[LocalName] = LocalObject
			return LocalObject, {
				RemoveLocal = function()
					NewState.Locals[LocalName] = nil
				end
			}
		end
		function NewState.RemoveLocal(RegisterIndex, LocalName)
			local LocalIndex = NewState.FindLocal(RegisterIndex, LocalName)
			assert(LocalIndex, "Failed to find the local variable!")
			NewState.Locals[LocalIndex] = nil
		end
		function NewState.FindLocal(RegisterIndex, LocalName)
			local FindByWhat = (RegisterIndex and "Register") or "Name"
			local FindWhat = RegisterIndex or LocalName
			for Index, Local in pairs(NewState.Locals) do
				if Local[FindByWhat] == FindWhat then
					return Index
				end
			end
		end
		
		function NewState.LoadInstructions(State)
			for Index, Instruction in pairs(State.Instructions) do
				table.insert(NewState.Instructions, Instruction)
				NewState.StackTopIndex = NewState.StackTopIndex + 1
			end
		end
		function NewState.LoadConstants(State)
			for Index, Constant in pairs(State.Constants) do
				table.insert(NewState.Constants, Constants)
			end
		end
		function NewState.FindOrCreateConstant(ConstantName)
			local ConstantIndex = Find(NewState.Constants, ConstantName)
			if not ConstantIndex then
				table.insert(NewState.Constants, ConstantName)
				return -(#NewState.Constants), false
			end
			return -ConstantIndex, true
		end
		
		return NewState
	end

	--[[ DO NOT DELETE
	local SolveExpression;
	function SolveExpression(Expression)
		local ExpressionSolvLoop;
		function ExpressionSolvLoop(Expression)
			if Expression["TYPE"] == "EXPRESSION" then
				local Left = ExpressionSolvLoop(Expression[1])
				local Operator = Expression[2]["TYPE"]
				local Right = ExpressionSolvLoop(Expression[3])
				if Operator == "ADD" then
					return Left + Right
				elseif Operator == "SUB" then
					return Left - Right
				elseif Operator == "POW" then
					return Left ^ Right
				elseif Operator == "DIV" then
					return Left / Right
				elseif Operator == "MUL" then
					return Left * Right
				end
			elseif Expression["TYPE"] == "NUMBER" then
				return tonumber(Expression[1])
			end
		end

		local Result = ExpressionSolvLoop(Expression)
		return Result
	end
	DO NOT DELETE --]]

	local Variable
	local ExpressionToState;
	local FunctionCall;
	function ExpressionToState(State, Expression)
		local TemporaryRegisters = {}
		
		local NewOperation;
		function NewOperation(Expression, IsIndex)
			if Expression["TYPE"] == "NUMBER" or Expression["TYPE"] == "STRING" then
				local ConstantIndex = State.FindOrCreateConstant(Expression[1])
				local ConstantRegister, Object = State.AllocateRegister()
				
				table.insert(TemporaryRegisters, Object)

				State.AppendInstruction("LOADK", ConstantRegister, ConstantIndex)
				return ConstantRegister, Object
				--return ConstantRegister
			elseif Expression["TYPE"] == "VARIABLE" then
				local AllocatedRegister, Object = Variable(State, Expression)
				table.insert(TemporaryRegisters, Object)

				return AllocatedRegister, Object
			elseif Expression["TYPE"] == "FUNCTION_CALL" then
				-- ... Or we can use "MOVE" instruction to copy returned
				-- from function contents to a new position
				local FuncResultReg, Object = FunctionCall(State, Expression, 1, true)
				table.insert(TemporaryRegisters, Object)
				-- State.AppendInstruction("MOVE", State.StackTopIndex, State.StackTopIndex - 1)
				return FuncResultReg, Object
			end

			local OperatorName = Expression[2]["SUBTYPE"] or Expression[2]["TYPE"]
			if OperatorName == "UNM" or OperatorName == "NOT" then
				local LeftPos = NewOperation(Expression[1])
				local ResultRegister, Object = State.AllocateRegister()
				table.insert(TemporaryRegisters, Object)
				State.AppendInstruction(OperatorName, ResultRegister, LeftPos)
				return ResultRegister, Object
			elseif OperatorName == "INDEX" then
				--[=[ LeftPos is a variable.
				State.FindOrCreateConstant(Expression[1])
				local LeftPos = State.Locals[Expression[1]]["Register"]
				local RightPos = NewOperation(Expression[3], true)

				local ResultRegister, Object = State.AllocateRegister()
				table.insert(TemporaryRegisters, Object)

				State.AppendInstruction("GETTABLE", ResultRegister, LeftPos, RightPos)
				return ResultRegister, Object --]=]
			end
			local LeftPos = NewOperation(Expression[1])
			local RightPos = NewOperation(Expression[3])

			local ResultRegister, Object = State.AllocateRegister()
			table.insert(TemporaryRegisters, Object)
			
			State.AppendInstruction(OperatorName, ResultRegister, LeftPos, RightPos)
			return ResultRegister, Object
		end

		local LatestUsedRegister, Object = NewOperation(Expression)
		Object.DeallocateRegister()
		for Index, Object in pairs(TemporaryRegisters) do
			Object.DeallocateRegister()
		end

		local RegisterToMove, Object = State.AllocateRegister()

		State.AllocateRegister(RegisterToMove)
		State.AppendInstruction("MOVE", RegisterToMove, LatestUsedRegister)
		
		return RegisterToMove, Object
	end

	local ParseKeywords;

	local ParseClosure;
	function ParseClosure(State, Table)
		return State, ParseKeywords(State, Table),
		       State.AppendInstruction("RETURN", 0, 1)
	end

	function Variable(State, Table)
		local VariableName = Table[1]
		local LocalObject = State.Locals[VariableName]

		local AllocatedRegister, Object = State.AllocateRegister()
		if LocalObject then
			local LocalRegister = LocalObject["Register"]
			State.AppendInstruction("MOVE", AllocatedRegister, LocalRegister)
		elseif not LocalObject then
			local ConstantIndex = State.FindOrCreateConstant(VariableName)
			State.AppendInstruction("GETGLOBAL", AllocatedRegister, ConstantIndex)
		end
		return AllocatedRegister, Object
	end
	
	function FunctionCall(State, Table, Returns, Return)
		local Arguments = Table["Arguments"]
		local FunctionName = Table["Value"]

		local FuncNameIndex,IsNew = State.FindOrCreateConstant(FunctionName)
		local FuncRegisterIndex, FuncObject = State.AllocateRegister()

		local TemporaryRegisters = {}
		
		State.AppendInstruction("GETGLOBAL", FuncRegisterIndex, FuncNameIndex)
		for Index, Argument in pairs(Arguments) do
			if Argument["TYPE"] == "STRING" or Argument["TYPE"] == "NUMBER" then
				local ConstantIndex, IsNew = State.FindOrCreateConstant(Argument[1])
				local ConstantRegister, Object = State.AllocateRegister()
				table.insert(TemporaryRegisters, Object)
				
				State.AppendInstruction("LOADK", ConstantRegister, ConstantIndex)
			elseif Argument["TYPE"] == "EXPRESSION" then
				
				-- local SolvedExpression = SolveExpression(Argument)
				-- local NewConstantIndex = State.FindOrCreateConstant(SolvedExpression)
				-- State.AppendInstruction("LOADK", State.StackTopIndex, NewConstantIndex)

				local ExprResultReg, ExprResultObject = ExpressionToState(State, Argument)
				table.insert(TemporaryRegisters, ExprResultObject)
			elseif Argument["TYPE"] == "FUNCTION_CALL" then
				local FuncResultReg, Object = FunctionCall(State, Argument, 1, true)
				table.insert(TemporaryRegisters, Object)
			elseif Argument["TYPE"] == "VARIABLE" then
				local AllocatedRegister, Object = Variable(State, Argument)
				table.insert(TemporaryRegisters, Object)
			else
				print("Invalid argument: '"..tostring(Argument["TYPE"]).."'")
			end
		end

		
		State.AppendInstruction("CALL", FuncRegisterIndex, #Arguments + 1, 1 + (Returns or 0))
		for Index, Object in pairs(TemporaryRegisters) do
			if Object.DeallocateRegister then
				Object.DeallocateRegister()
			else
				error("Unknown object")
			end
		end
		
		if Return then
			FuncObject.DeallocateRegister()
		
			local AllocatedRegister, Object = State.AllocateRegister()
			State.AppendInstruction("MOVE", AllocatedRegister, FuncRegisterIndex)
			
			return AllocatedRegister, Object
		end
		return FuncRegisterIndex, #Arguments + FuncRegisterIndex
	end
	
	function ParseKeywords(State, Keywords)
		local TemporaryObjects = {}
		
		local ClonedRegisters = Helpers.TableClone(State.Registers)
		local ClonedLocals = Helpers.TableClone(State.Locals)
		
		for Index, Keyword in ipairs(Keywords) do
			local KeywordType = Keyword["TYPE"]
			local NewExpression = Keyword["Expression"]
			local NewCodeBlock = Keyword["CodeBlock"]

			if KeywordType == "IF" then
				local ExpressionResult, Object = ExpressionToState(State, NewExpression)
				table.insert(TemporaryObjects, Object)

				State.AppendInstruction("TEST", ExpressionResult, 0, 0)
			elseif KeywordType == "DO" then
				
				ParseKeywords(State, Keyword["CodeBlock"])
			elseif KeywordType == "WHILE" then
		
			elseif KeywordType == "REPEAT" then
			elseif KeywordType == "FUNCTION_CALL" then
				
				local FuncResultReg, Object = FunctionCall(State, Keyword, 1, true)
				table.insert(TemporaryObjects, Object)
			elseif KeywordType == "VARIABLE_ASSIGMENT" then
				local ExpressionResult, Object = ExpressionToState(State, NewExpression)
				local VariableName = Keyword["Name"]

				Object.DeallocateRegister()
				if State.Locals[VariableName] then
					local VariableRegister = State.Locals[VariableName]["Register"]
					State.AppendInstruction("MOVE", VariableRegister, ExpressionResult)
				else
					local ConstantIndex = State.FindOrCreateConstant(VariableName)
					State.AppendInstruction("SETGLOBAL", ConstantIndex, ExpressionResult)
				end
			elseif KeywordType == "LOCAL_ASSIGMENT" then
				local ExpressionResult, Object = ExpressionToState(State, NewExpression)
				table.insert(TemporaryObjects, Object)

				local Local, LocalObject = State.AddLocal(Keyword["Name"], ExpressionResult)
				table.insert(TemporaryObjects, LocalObject)
			end
		
		end

		State.Locals = ClonedLocals
		State.Registers = ClonedRegisters
		
		--[[ DO NOT DELETE
		for Index, Object in pairs(TemporaryObjects) do
			if Object.DeallocateRegister then
				Object.DeallocateRegister()
			elseif Object.RemoveLocal then
				Object.RemoveLocal()
			end
		end
		DO NOT DELETE --]]
	end

	local ScriptState = CreateState()

	return ScriptState,
	       ParseClosure(ScriptState, Tokens)
end

-- Perform syntax check and convert human readable
-- instructions to real, machine readable instructions for VM
function Parser.ParseAssembly(String, Constants, Upvalues, Environment)
	local Lines = Helpers.GetLines(String)
	local _Index = 1

	local Constants, Instructions, Environment = Constants or {}, {}, Environment or {}

	-- Store the last index for tables so we don't need to call slow table.insert function
	local Constants_Index, Instructions_Index = 1, 1

	for Index,Line in ipairs(Lines) do
		-- Check if the line is not empty or it's not just a big comment
		local StrippedLine = Line:match("([\1-\58\60-\255]*)")
		if StrippedLine:gsub("%s", "") ~= "" then
		
			local InstructionPattern = "^%s*([a-zA-Z]+)%s+(%-?%d*)%s*,?%s*(%-?%d*)%s*,?%s*(%-?%d*)%s*$"
			local ConstantPattern1 = "%s*(%b'')%s*"
			local ConstantPattern2 = '%s*(%b"")%s*'

			local OPCode, Argument1, Argument2, Argument3 = StrippedLine:match(InstructionPattern)
			Argument1 = (Argument1 ~= "" and Argument1) or nil
			Argument2 = (Argument2 ~= "" and Argument2) or nil
			Argument3 = (Argument3 ~= "" and Argument3) or nil

			-- Check if this is an instruction
			if OPCode and OPCodes.OP_Table[OPCode:upper()] then
				local OPCodeTable = OPCodes.OP_Table[OPCode:upper()]

				local ExpectedArguments = OPCodeTable[1]
				local TotalArguments = {Argument1, Argument2, Argument3}

				if #TotalArguments ~= ExpectedArguments then
					-- TODO: Error handling
					return print(("%s: Invalid ammount of params: %d, Expected: %d")
					             :format(OPCode, #TotalArguments, ExpectedArguments))
				else
					Instructions[Instructions_Index] = {
						OPCodeTable[2],tonumber(Argument1),tonumber(Argument2),
						tonumber(Argument3)
					}
					Instructions_Index = Instructions_Index + 1
				end
			elseif OPCode then
				return print((":%d Invalid OPCcode: %s"):format(Index, OPCode))
			else
				local Constant = StrippedLine:match(ConstantPattern1) or
				                 StrippedLine:match(ConstantPattern2)
	
				if not Constant then
					-- Check if this is a number
					local Number = StrippedLine:match("^%s*(%-?%d+%.?%d*)")
					if tonumber(Number) then
						Constants[Constants_Index] = tonumber(Number)
						Constants_Index = Constants_Index + 1
					else
						return print(("Line: %d invalid combination of opcode and operands")
						             :format(Index))
					end
				elseif Constant then
					-- Check if there's already instructions
 					-- if Instructions_Index > 1 then
					-- 	return print(string.format("Line: %d You can't assign new constants after instructions!", Index))
					-- end

					-- Add a new constant and remove quotes from it.
					Constants[Constants_Index] = Constant:sub(2, #Constant - 1)
					Constants_Index = Constants_Index + 1
				end
			end
		end
	end
	return Instructions, Constants
end

return Parser
