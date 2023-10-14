--[[
  Name: Optimizer.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local OPCodes = require("OPCodes/Main")

--* Export library functions *--
local Unpack = unpack or table.unpack
local Find = table.find or Helpers.TableFind

local Optimizer = Class{

}

--[==[
function Optimizer.Optimize(Instructions, Constants, Globals, Level)
    local Constants = Constants or {}
    local Globals = Globals or getfenv()
    local Level = Level or 0
    
    for Index, Value in pairs(Constants) do
        if Index >= 0 then
            Constants[-Index] = Value
        end
    end

    local TempRegister = {}
    local NewInstructions = {}
    
    local function GetValue(Register, IsRK)
        return (IsRK and Constants[math.max(1, Register)]) or TempRegister[Register]
    end

    local function Replicate(Register1, Register2, Value)
        local Value = Value or GetValue(Register2, true)
        TempRegister[Register1] = Value
    end

    local function Solve(OPName, A, B, C)
        if OPName == "ADD" then
            local Value1, Value2 = GetValue(B, true), GetValue(C, true)
            if type(Value1) == "number" and type(Value2) == "number" then
                return true, Value1 + Value2
            end
        end

        return false
    end

    local function FindOrCreateConstant(ConstantName)
        local ConstantIndex = Find(Constants, ConstantName)
        if not ConstantIndex then
            table.insert(Constants, ConstantName)
            ConstantIndex = #Constants
        end
        return -ConstantIndex
    end

    local Instruction_Analysis = {
        ["MOVE"] = function(A, B, C)
            return { Used = {B}, Changed = {A}}
        end,
        ["LOADK"] = function(A, B, C)
            return { Used = {}, Changed = {A}}
        end,
        ["LOADBOOL"] = function(A, B, C)
            return { Used = {}, Changed = {A}, Jump = (C and C ~= 0)}
        end,
        ["LOADNIL"] = function(A, B, C)
            local ChangedRegisters = {}
            for Register = A, B do
                table.insert(ChangedRegisters, Register)
            end
            return { Used = {}, Changed = ChangedRegisters }
        end,
        ["GETUPVAL"] = function(A, B, C)
            return { Used = {}, Changed = {A} }
        end,
        ["GETGLOBAL"] = function(A, B, C)
            return { Used = {}, Changed = {A} }
        end,
        ["GETTABLE"] = function(A, B, C)
            return { Used = {B}, Changed = {A} }
        end,
        ["SETGLOBAL"] = function(A, B, C)
            return { Used = {B}, Changed = {} }
        end,
        ["SETUPVAL"] = function(A, B, C)
            return { Used = {B}, Changed = {} }
        end,
        ["SETTABLE"] = function(A, B, C)
            -- "A" here is not fully changed, 
            -- just some element of the table
            -- we don't count it.
            local Used = {}

            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end

            return { Changed = {}, Used = Used }
        end,
        ["NEWTABLE"] = function(A, B, C)
            return { Used = {}, Changed = {A} }
        end,
        ["SELF"] = function(A, B, C)
            local Used = {}
            local Changed = {}

            table.insert(Changed, A)
            table.insert(Changed, A + 1)
            table.insert(Used, B)
            if C >= 0 then table.insert(Used, C) end
            
            return { Used = Used, Changed = Changed }
        end,
        ["ADD"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["SUB"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["MUL"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["DIV"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["MOD"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["POW"] = function(A, B, C)
            local Used = {}
            
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            return { Used = Used, Changed = {A} }
        end,
        ["UNM"] = function(A, B, C)
            return { Used = {B}, Changed = {A} }
        end,
        ["NOT"] = function(A, B, C)
            return { Used = {B}, Changed = {A} }
        end,
        ["LEN"] = function(A, B, C)
            return { Used = {B}, Changed = {A} }
        end,
        ["UNM"] = function(A, B, C)
            local Used = {A}
            for Register = B, C do
                table.insert(Used, Register)
            end
            return { Used = Used, Changed = {A} }
        end,
        ["JMP"] = function(A, B, C)
            return { Used = {}, Changed = {}, Jump = A }
        end,
        ["EQ"] = function(A, B, C)
            local Used = {}
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            local RK_B = Constants[B] or TempRegister[B]
            local RK_C = Constants[C] or TempRegister[C]

            local HasJumped = (RK_B == RK_C) ~= (A == 1)
            return { Used = Used, Changed = {}, Jump = (HasJumped and 1)}
        end,
        ["LT"] = function(A, B, C)
            local Used = {}
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            local RK_B = Constants[B] or TempRegister[B]
            local RK_C = Constants[C] or TempRegister[C]

            local HasJumped = ( RK_B < RK_C ) ~= (A == 1)
            return { Used = Used, Changed = {}, Jump = (HasJumped and 1)}
        end,
        ["LE"] = function(A, B, C)
            local Used = {}
            if B >= 0 then table.insert(Used, B) end
            if C >= 0 then table.insert(Used, C) end
            local RK_B = Constants[B] or TempRegister[B]
            local RK_C = Constants[C] or TempRegister[C]

            local HasJumped = ( RK_B <= RK_C ) ~= (A == 1)
            return { Used = Used, Changed = {}, Jump = (HasJumped and 1)}
        end,
        ["TEST"] = function(A, B, C)
            local HasJumped = TempRegister[A] ~= (B == 1)
            return { Used = {A}, Changed = {}, Jump = (HasJumped and 1)}
        end,
        ["TESTSET"] = function(A, B, C)
            local Changed = {}
            local HasJumped;
            if TempRegister[B] == (C == 1) then table.inesrt(Changed, A)
            else HasJumped = true end
            return { Used = {B}, Changed = Changed, Jump = (HasJumped and 1)}
        end,
        ["CALL"] = function(A, B, C)
            local Used, Changed = {}, {}
            for Register = A, A + B - 1 do
                table.insert(Used, Register)
            end
            for Register = A, A + C - 2 do
                table.insert(Changed, Register)
            end
            return { Used = Used, Changed = Changed }
        end,
        ["TAILCALL"] = function(A, B, C)
            local Used = {}
            for Register = A, A + B - 1 do
                table.insert(Used, Register)
            end
            return { Used = Used, Changed = {}}
        end,
        ["RETURN"] = function(A, B, C)
            local Used = {}
            for Register = A, A + B - 2 do
                table.insert(Used, Register)
            end
            return { Used = Used, Changed = {}}
        end,
        ["FORLOOP"] = function(A, B, C)
            local Used, Changed = {}, {}
            local HasJumped

            table.insert(Used, A)
            table.insert(Used, A + 1)
            table.insert(Used, A + 2)

            table.insert(Changed, A)
            if Register[A] <= Register[A + 1] then
                HasJumped = true
                table.insert(Changed, A + 3)
            end
            return { Used = Used, Changed = Changed, Jump = (HasJumped and B)}
        end,
        ["FORPREP"] = function(A, B, C)
            return { Used = {A, A + 2}, Changed = {A}, Jump = B}
        end
        --["TFORLOOP"] = function(A, B, C)
        --    local Used, Changed = {}, {}
        --end,
    }

    local function IsRegisterUsed(Register, StartFrom)
        local StartFrom = StartFrom or 0

        for Index = StartFrom + 1, #Instructions do
            local Value = Instructions[Index]
            local OPName, A, B, C = unpack(Value)
            local Result = Instruction_Analysis[OPName](A, B, C)
            
            local Used = Result.Used or {}
            local Changed = Result.Changed or {}

            local IsUsed, IsChanged
            
            for Index2, Value2 in pairs(Used) do
                if Value2 == Register then IsUsed = true end
            end
            for Index2, Value2 in pairs(Changed) do
                if Value2 == Register then IsChanged = true end
            end

            return IsUsed, IsChanged
        end

        return false
    end

    local TotalOptimizations = 0
    for Index, Value in pairs(Instructions) do
        local Pass = true
        local OPName, A, B, C = Unpack(Value)

        if OPName == "MOVE" then
            local IsUsed, IsChanged = IsRegisterUsed(A, Index)
            if IsUsed then
                Pass = (A ~= B) and (TempRegister[A] ~= TempRegister[B])
                Replicate(A, B)
            else
                Pass = false
            end
        elseif OPName == "LOADK" then
            local A_Value = GetValue(A, false)
            local B_Value = GetValue(B, true)
            
            local IsUsed = IsRegisterUsed(A, Index)
            -- print(("[%s:%d]: %s, %s, %s || Used: %s"):format(OPName, Index, tostring(A), tostring(B), tostring(C), tostring(IsUsed)))
            if IsUsed then
                Pass = (A_Value ~= B_Value)
                Replicate(A, B_Value)
            else
                Pass = false
            end
        elseif OPName == "GETGLOBAL" then
            Replicate(A, nil, Globals[Constants[B]])
        elseif OPName == "ADD" then
            local Success, Result = Solve(OPName, A, B, C)
            if Success then
                Pass = false
               
                Replicate(A, Result)
                
                local ConstantIndex = FindOrCreateConstant(Result)
                table.insert(NewInstructions, {"LOADK", A, ConstantIndex})
            end
        end

        if Pass then
            table.insert(NewInstructions, {OPName, A, B, C})
        else
            TotalOptimizations = TotalOptimizations + 1
        end
    end

    if Level > 1 and TotalOptimizations > 0 then
        return Optimizer.Optimize(NewInstructions, Constants, Globals, Level - 1)
    end
    return NewInstructions, Constants
end

return Optimizer
--]==]