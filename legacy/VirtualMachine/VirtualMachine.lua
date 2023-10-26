--[[
  Name: VirtualMachine.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/05/XX
--]]

local OPModule = require("OPCodes/Main")
local Helpers = require("Helpers/Helpers")


local function VM(Instructions, Constants, Upvals, Protos, Env)


  -- Get global variables table
  Env = Env or ((getfenv and getfenv()) or _ENV)

  -- Get constants table
  Constants = Constants or {}

  -- Reindex all constants to make it with negative indicies
  for i, v in ipairs(Constants) do
    Constants[-i] = v
    Constants[i] = nil
  end

  -- Set upvalues table
  local Upvals = Upvals or {}
  local Register = {}
  local Debug = {}

  -- Set variables for debugging
  local StackTrace, StackTraceTB, StackTraceTB;
  local RealRegister = Register;

  -- Define program counter
  local PC = 1

  -- Dump virtual machine's contents.
  -- 1 = constant dump, 2 = register dump.
  function Debug.Dump(Mode)
    local ConstantsStr = "*--------Called constant dump--------*"
    local RegistersStr = "*--------Called register dump--------*"

    local TOP_LENGTH = math.max(#RegistersStr, #ConstantsStr)

    local BottomStr = "*------------------------------------*"
    local Table = Mode == 1 and Constants or Register
  
    print(Mode == 1 and ConstantsStr or RegistersStr)

    Helpers.BoxPrint(Table)
    
    print(BottomStr)
  end
  

  function Debug.StartStackTrace()
    if StackTrace then return end
    
    StackTrace = true
    StackTraceTB = { _Index = {}, _NewIndex = {}, Instructions = {} }
    
    local RegisterMT = setmetatable({}, {})
    local TempMT = getmetatable(RegisterMT)
    
    function TempMT.__index(self, index)
      local ReturnValue = RealRegister[index]
      local Information = {
        OPCode = Instructions[PC][1],
        OPCodeIndex = PC,
        RegisterIndex = index,
        Return = ReturnValue,
        A = Instructions[PC][2],
        B = Instructions[PC][3],
        C = Instructions[PC][4]
       }
      table.insert(StackTraceTB._Index, Information)
      return ReturnValue
    end
    
    function TempMT.__newindex(self, index, value)
      local OldValue = RealRegister[index]
      RealRegister[index] = value
      local Information = {
        OPCode = Instructions[PC][1],
        OPCodeIndex = PC,
        RegisterIndex = index,
        Value = value,
        OldValue = OldValue,
        A = Instructions[PC][2],
        B = Instructions[PC][3],
        C = Instructions[PC][4]
      }
      table.insert(StackTraceTB._NewIndex, Information)
    end
    
    Register = RegisterMT
  end
    
  function Debug.StopStackTrace()
    if not StackTrace then return end

    Register = RealRegister
    local IndexLog, NewIndexLog = "", ""
  
    for i, v in ipairs(StackTraceTB._Index) do
      local OPCode = v.OPCode

      local A, B, C = tostring(v.A), tostring(v.B), tostring(v.C)

      local Ret = v.Return
      if type(Ret) == "function" then
        Ret = string.format("(%s)", tostring(Ret))
      end
      local InstIndex = tostring(v.OPCodeIndex)
      local RegIndex = tostring(v.RegisterIndex)
      local OPName = tostring(OPModule.OP_ENUM[OPCode])
      IndexLog = IndexLog .. string.format("\n\t[%s:%s %s, %s, %s] Accessed Register[%s] (%s)",
        InstIndex, OPName, A, B, C, RegIndex, tostring(Ret))
    end
  
    for i, v in ipairs(StackTraceTB._NewIndex) do
      local OPCode = v.OPCode
      
      local A, B, C = tostring(v.A), tostring(v.B), tostring(v.C)
      
      local OPName = tostring(OPModule.OP_ENUM[OPCode])
      local RegIndex = v.RegisterIndex
      local Value = tostring(v.Value)
      local OldValue = tostring(v.OldValue)
      if type(Value) == "function" then
        Value = string.format("(%s)", tostring(Value))
      end
      if type(OldValue) == "function" then
        OldValue = string.format("(%s)", tostring(OldValue))
      end
      local InstIndex = v.OPCodeIndex
      NewIndexLog = NewIndexLog .. string.format("\n\t[%s:%s %s, %s, %s] Register[%d] = %s (old: %s)",
        InstIndex, OPName, A, B, C, RegIndex, Value, OldValue)
    end
  
    print(string.format("_Index log: {%s\n}\n_NewIndexLog: {%s\n}", IndexLog, NewIndexLog))
    StackTraceTB = {}
  end

  local InstructionFunctions = {

    -- OP_MOVE [A, B]    R(A) := R(B)
    -- Copy a value between registers
    function(A, B)
      Register[A] = Register[B]
    end,

    -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
    -- Load a constant into a register
    function(A, B)
      Register[A] = Constants[B]
    end,

    -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
    -- Load a boolean into a register
    function(A, B, C)
      Register[A] = (B == 1)
      if C and C ~= 0 then
        PC = PC + 1
      end
    end,

    -- OP_LOADNIL [A, B]    R(A) := ... := R(B) := nil
    -- Load nil values into a range of registers
    function(A, B)
      for Index = A, B do
        Register[Index] = nil
      end
    end,

    -- OP_GETUPVAL [A, B]    R(A) := UpValue[B]
    -- Read an upvalue into a register
    function(A, B)
      Register[A] = Upvalues[B]
    end,

    -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
    -- Load a global into a register
    function(A, B)
      Register[A] = Env[Constants[B]]
    end,

    -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
    -- Read a table element into a register
    function(A, B, C)
      Register[A] = Register[B][Constants[C] or Register[C]]
    end,

    -- OP_SETGLOBAL [A, Bx]    Gbl[Kst(Bx)] := R(A)
    -- Write a register value into a global
    function(A, Bx)
      Env[Constants[A]] = Register[Bx]
    end,

    -- OP_SETUPVAL [A, B]    UpValue[B] := R(A)
    -- Write a register value into an upvalue
    function(A, B)
      Upvalues[A] = Register[B]
    end,

    -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
    -- Write a register value into a table element
    function(A, B, C)
      Register[A][ Constants[B] or Register[B] ] = (Constants[C] or Register[C])
    end,

    -- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
    -- Create a new table
    function(A, B, C)
      Register[A] = {}
    end,

    -- OP_SELF [A, B, C]    R(A+1) := R(B); R(A) := R(B)[RK(C)]
    -- Prepare an object method for calling
    function(A, B, C)
      Register[A + 1] = Register[B]
      Register[A] = Register[B][Constants[C] or Register[C]]
    end,

    -- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
    -- Addition operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) + (Constants[C] or Register[C])
    end,

    -- OP_SUB [A, B, C]    R(A) := RK(B) - RK(C)
    -- Subtraction operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) - (Constants[C] or Register[C])
    end,

    -- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
    -- Multiplication operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) * (Constants[C] or Register[C])
    end,

    -- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
    -- Division operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) / (Constants[C] or Register[C])
    end,

    -- OP_MOD [A, B, C]    R(A) := RK(B) % RK(C)
    -- Modulus (remainder) operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) % (Constants[C] or Register[C])
    end,

    -- OP_POW [A, B, C]    R(A) := RK(B) ^ RK(C)
    -- Exponentation operator
    function(A, B, C)
      Register[A] = (Constants[B] or Register[B]) ^ (Constants[C] or Register[C])
    end,

    -- OP_UNM [A, B]    R(A) := -R(B)
    -- Unary minus
    function(A, B, C)
      Register[A] = -Register[B]
    end,

    -- OP_NOT [A, B]    R(A) := not R(B)
    -- Logical NOT operator
    function(A, B, C)
      Register[A] = not Register[B]
    end,

    -- OP_LEN [A, B]    R(A) := length of R(B)
    -- Length operator
    function(A, B, C)
      Register[A] = #Register[B]
    end,

    -- OP_CONCAT [A, B, C]    R(A) := R(B).. ... ..R(C)
      -- Concatenate a range of registers
    function(A, B, C)
      local String = ""
      for i = B, C do
        String = String .. Register[i]
      end
      Register[A] = Register[A] .. String
    end,

    -- OP_JMP [sBx]    pc+=sBx
    -- Unconditional jump
    function(A)
      PC = PC + A
    end,

    -- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++ 
    -- Equality test, with conditional jump
    function(A, B, C)
      local RK_B = Constants[B] or Register[B]
      local RK_C = Constants[C] or Register[C]

      if (RK_B == RK_C) ~= (A == 1) then
        PC = PC + 1
      end
    end,

    -- OP_LT [A, B, C]    if ((RK(B) <  RK(C)) ~= A) then pc++
    -- Less than test, with conditional jump
    function(A, B, C)
      local RK_B = Constants[B] or Register[B]
      local RK_C = Constants[C] or Register[C]

      if ( RK_B < RK_C ) ~= (A == 1) then
        PC = PC + 1
      end
    end,

    -- OP_LE [A, B, C]    if ((RK(B) <= RK(C)) ~= A) then pc++
    -- Less than or equal to test, with conditional jump
    function(A, B, C)
      local RK_B = Constants[B] or Register[B]
      local RK_C = Constants[C] or Register[C]

      if ( RK_B <= RK_C ) ~= (A == 1) then
        PC = PC + 1
      end
    end,

    -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
    -- Boolean test, with conditional jump
    function(A, B, C)
      B = C or B -- For future compabillity.
      if Register[A] ~= (B == 1) then
        PC = PC + 1
      end
    end,

    -- OP_TESTSET [A, B, C]    if (R(B) <=> C) then R(A) := R(B) else pc++
    -- Boolean test, with conditional jump and assignment
    function(A, B, C)
      if Register[B] == (C == 1) then
        Register[A] = Register[B]
      else
        PC = PC + 1
      end
    end,

    -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    -- Call a closure
    function(A, B, C)
      local Arguments = {}

      local _Index = 1
      for i = A + 1, A + B - 1 do
        Arguments[_Index] = Register[i]
        _Index = _Index + 1
      end
      local Results = {Register[A](unpack(Arguments))}
      
      _Index = 1
      for i = A, A + C - 2 do
        Register[i] = Results[_Index]
        _Index = _Index + 1
      end
    end,

    -- OP_TAILCALL [A, B, C]    return R(A)(R(A+1), ... ,R(A+B-1))
    -- Perform a tail call
    function(A, B, C)
      local Arguments = {}
      local _Index = 1
      for i = A + 1, A + B - 1 do
        Arguments[_Index] = Register[i]
        _Index = _Index + 1
      end
      return Register[A](unpack(Arguments))
    end,

    -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
    -- Return from function call
    function(A, B)
      local Table1 = {}
      local _Index = 1
      for i = A, A + B - 2 do
        Table1[_Index] = Register[i]
        _Index = _Index + 1
      end

      if StackTrace then
        Debug.StopStackTrace()
      end
      return unpack(Table1)
    end,

    -- OP_FORLOOP [A, sBx]   R(A)+=R(A+2);
    --                       if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
    -- Iterate a numeric for loop 
    function(A, B)
      Register[A] = Register[A] + Register[A + 2]
      
      if Register[A] <= Register[A + 1] then
        PC = PC + B
        Register[A + 3] = Register[A]
      end
    end,

    -- OP_FORPREP [A, sBx]    R(A)-=R(A+2); pc+=sBx
    -- Initialization for a numeric for loop
    function(A, B)
      Register[A] = Register[A] - Register[A + 2]
      PC = PC + B
    end,

    -- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
    --                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
    -- Iterate a generic for loop
    function(A, B, C)
      local C = C or B
      local Table1 = {Register[A](Register[A + 1], Register[A + 2])}
      local _Index = 1
      for i = A + 3, A + 2 + C do
        Register[i] = Table1[_Index]
        _Index = _Index + 1
      end
      if Register[A + 3] ~= nil then
        Register[A + 2] = Register[A + 3]
      else
        PC = PC + 1
      end
    end,

    -- OP_SETLIST [A, B, C]    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
    -- Set a range of array elements for a table
    function(A, B, C)
      local Table = Register[A]
      local _Index = 1
      -- I changed here "A + B" to "A + B + 1",
      -- I need to check it later.
      for i = A + 1, A + B + 1, C do
        Table[_Index] = Register[i]
        _Index = _Index + 1
      end
    end,

    -- OP_CLOSE [A]
    -- close( R(0), ..., R(A) )
    -- close all variables in the stack up to (>=) R(A)
    function(A)
      local level = Frame.Base + A
      while #Registers > level do
        table.remove(Registers)
      end
    end,

    -- OP_CLOSURE [A, Bx]
    -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
    -- Create a closure of a function prototype
    function(A, B)
      local prototype = Prototypes[B + 1]
      local upvalues = {}
      for i = 1, prototype.NumUpvalues do
        local upvalue = Register[A]
        upvalues[i] = upvalue
      end
      local closure = {Prototype = prototype, Upvalues = upvalues}
      Registers[A] = closure
    end,

    -- OP_VARARG [A, B]
    -- R(A), R(A+1), ..., R(A+B-1) = vararg
    -- assign vararg function arguments to registers
    function(A, B)
      local varargs = Varargs
      if varargs == nil then
        varargs = {}
      end
      for i = A, A + B - 1 do
        if i < Frame.Top then
          Registers[i] = Frame[i]
        else
          Registers[i] = varargs[i - Frame.Top + 1]
        end
      end
    end
  }

  local function VirtualMachineHandler()
    while (true) do
      local CurrentInstruction = Instructions[PC]
      if not CurrentInstruction then

        -- End this loop if OP_RETURN is not given
        -- Putting OP_RETURN in the end is just a good practice.
        print("[Warning]: Your code should always end with OP_RETURN!")

        if StackTrace then
          Debug.StopStackTrace()
        end
        return nil
      end

      -- Add more debugging info
      if StackTrace then
        StackTraceTB[PC] = CurrentInstruction
      end

      local OPCode = CurrentInstruction[1]
      local FunctionForInstruction = InstructionFunctions[OPCode]
      if OPCode ~= 31 and OPCode ~= 30 then
        FunctionForInstruction(CurrentInstruction[2], CurrentInstruction[3], CurrentInstruction[4] )
      else
        return FunctionForInstruction( CurrentInstruction[2], CurrentInstruction[3], CurrentInstruction[4] )
      end

      PC = PC + 1
    end
  end

  return function(DEBUG)
    if DEBUG then
      Debug.StartStackTrace()
    end

    local IsSuccessful, ReturnValue = pcall(VirtualMachineHandler)

    xpcall(VirtualMachineHandler, function(Return)
      print(Return)
      print(debug.traceback())
      Debug.Dump(0)
      Debug.Dump(1)

      Debug.StopStackTrace()
    end)
  end

end

return VM