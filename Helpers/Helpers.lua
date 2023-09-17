--[[
  Name: Helpers.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-08-XX
  All Rights Reserved.
]]

--* Export library functions *--
local rep = string.rep
local gmatch = string.gmatch
local char = string.char
local byte = string.byte
local gsub = string.gsub
local len = string.len
local floor = math.floor
local max = math.max
local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack

--* Library object *--
local Helpers = {}

--* Functions *--

-- Inverts the keys and values of a table.
-- Example: {h:"e", l:"l", o:"!"} -> {e:"h", l:"l", "!":"o"}
function Helpers.InvertTableKeyValue(inputTable)
  local newTable = {}
  for index, value in pairs(inputTable) do
    newTable[value] = index
  end

  return newTable
end

-- Reverses the order of elements in a numeric indexed table.
-- Example: {1,2,3} -> {3,2,1}
function Helpers.ReverseNumericTable(inputTable)
  local newTable = {}
  for index = 1, #inputTable, 1 do
    local value = inputTable[index]
    newTable[#inputTable - index + 1] = value
  end
  return newTable
end

-- Insert values from table2 to table1
function Helpers.MergeTable(table1, table2)
  for _, value in ipairs(table2) do
    insert(table1, value)
  end
end

-- Find a value in a table
function Helpers.TableFind(Table, Value)
  for Index, TableValue in pairs(Table) do
    if Value == TableValue then
      return Index
    end
  end
  return nil
end

-- Get multiple elements from a table and insert them into another table
function Helpers.GetTableElementsFromTo(Table, min, max)
  local tb = {}
  for i = min, max do
    insert(tb, Table[i])
  end
  return tb
end

-- Clone a table and all values in it
function Helpers.TableClone(Table)
  local Recursion;
  function Recursion(Table)
    local ClonedTable = {}
    for Index, Value in pairs(Table) do
      if type(Value) ~= "table" then
        ClonedTable[Index] = Value
      else
        ClonedTable[Index] = Recursion(Value)
      end
    end
    return ClonedTable
  end
  return Recursion(Table)
end

-- Find Table1 indicies in stream of Table2 values,
-- with the higher priority for more lengthy values.
-- Really useful in token matching.
function Helpers.TableIndexSearch(Table1, Table2, Table2Index)
  local BestMatch = "";
  for Index in pairs(Table1) do
    local Table2CompIndex = Table2Index
    local String = {}
    while #Index > #String do
      local Table2Value = Table2[Table2CompIndex]
      if not Table2Value then break end
      insert(String, Table2Value)
      Table2CompIndex = Table2CompIndex + 1
    end
    String = concat(String, "")
    if String == Index and #String > #BestMatch then
      BestMatch = String
    end
  end

  return (BestMatch ~= "" and BestMatch)
end

-- Apparently Lua stops at gaps in tables
-- so table {1, nil, 3, 4} would have length of 1
-- my method is slower but better. 
function Helpers.TableLen(Table)
  local TableLength = 0
  for Index, Value in pairs(Table) do
    TableLength = TableLength + 1
  end
  return TableLength
end

-- Clear all element of a table without copying it
function Helpers.ClearTable(Table)
  for Index, _ in pairs(Table) do
    Table[Index] = nil
  end
  return Table
end

-- Copy first-level values from Table1 to Table2
function Helpers.CopyTableElements(Table1, Table2)
  for Index, Value in pairs(Table1) do
    Table2[Index] = Value
  end
  return Table2
end

-- Convert a table to a string, recursively
function Helpers.StringifyTable(Table, Spacing)
  local Spacing = Spacing or 2
  local SpacingString = rep(" ", Spacing)

  local VisitTable, VisitTableValue;
  local function VisitTableElement(Lines, Indentation, Index, Value)
    local FormatString = (type(Value) == "table" and "%s[%s] = %s {") or "%s[%s] = %s";
      
    local CurrentIndentation = rep(SpacingString, Indentation)
    insert(Lines, FormatString:format(CurrentIndentation, tostring(Index), tostring(Value)))
    if type(Value) == "table" then
      insert(Lines, VisitTable(Value, Indentation + 1))
      insert(Lines, CurrentIndentation .. "}")
    end
  end

  local VisitedTables = {}
  function VisitTable(Table, Indentation)
    if VisitedTables[Table] and VisitedTables[Table] >= 3 then
      -- Terminate any possibility of an infinite recursion
      return rep(SpacingString, Indentation) .. "<Repeated table>"
    end
    
    VisitedTables[Table] = VisitedTables[Table] and VisitedTables[Table] + 1 or 0

    local Lines = {}
    for Index, Value in pairs(Table) do
      VisitTableElement(Lines, Indentation, Index, Value)
    end
    
    return concat(Lines, "\n")
  end

  return "{\n" .. VisitTable(Table, 1) .. "\n}"
end

-- Serialize a value to a string
function Helpers.SerializeValue(Value)
  local Value = Value
  local ValueType = type(Value)
  
  if ValueType == "string" then
    return "'" .. Value .. "'"
  elseif ValueType == "number" then
    return tostring(Value)
  elseif "function" == ValueType or "userdata" == ValueType or "table" == ValueType or "nil" == ValueType then
    return ValueType
  else
    return tostring(Value)
  end
end

-- 
function Helpers.TableToPrettyString(tableData)
  local SerializeValue = Helpers.SerializeValue

  -- Calculate the maximum length of each column
  for _, row in pairs(tableData) do
    for key, value in pairs(row) do
      row[key] = SerializeValue(value)
    end
  end

  local maxLengths = {}
  for _, row in pairs(tableData) do
    for key, value in pairs(row) do
      local valueLength = #tostring(value)
      local keyLength = #tostring(key)
      maxLengths[key] = max(maxLengths[key] or 0, keyLength, valueLength)
    end
  end

  -- Create the header row
  local header = "|"
  local separator = "+"
  for key, length in pairs(maxLengths) do
    local key = tostring(key)

    local padding = rep(" ", floor((length - #key) / 2))
    local extraSpace = (length % 2 == #key % 2) and "" or " "

    header = header .. padding .. key .. padding .. extraSpace .. "|"
    separator = separator .. rep("-", length) .. "+"
  end

  local rows = {}
  for _, row in pairs(tableData) do
    local columns = {}
    for key, length in pairs(maxLengths) do
      local column = "|"
      local value = tostring(row[key] or "")
      local padding = rep(" ", floor((length - #value) / 2))

      column = column .. padding .. value .. padding .. (length % 2 == #value % 2 and "" or " ")
      insert(columns, column)
    end
    insert(rows, concat(columns) .. "|")
  end

  -- Concatenate the rows to form the final CSV-style string
  local csvStyleString = header .. "\n" .. separator .. "\n" .. table.concat(rows, "\n") .. "\n" .. separator
  return csvStyleString
end

-- Recursively compare two tables
function Helpers.TablesEqual(Table, ...)
  local CheckTables;
  local CheckValue;

  local Tables = {...}
  function CheckValue(Table1, Table2, Index)
    local Value1 = Table1[Index]
    local Value2 = Table2[Index]
    if type(Value1) == "table" and type(Value2) == "table" then
      local AreEqual = Helpers.TableEqual(Value1, Value2)
      if not AreEqual then return false end
    elseif Value1 ~= Value2 then
      return false
    end
    return true
  end;

  return true
end

-- This function concats multiple lines with the same spacing
function Helpers.AlignLines(Table)
  -- Find the longest string in each column
  local MaxLengths = {}
  for _, Row in pairs(Table) do
    for Column, Value in pairs(Row) do
      local Length = len(tostring(Value))
      if not MaxLengths[Column] or Length > MaxLengths[Column] then
        MaxLengths[Column] = Length
      end
    end
  end

  -- Concat each line with the same spacing
  local Lines = {}
  for _, Row in pairs(Table) do
    local Line = {}
    for Column, Value in pairs(Row) do
      local Spacing = rep(" ", MaxLengths[Column] - len(Value))
      insert(Line, Value .. Spacing)
    end
    insert(Lines, concat(Line, ""))
  end

  return concat(Lines, "\n")
end

-- Read a file from a given path
function Helpers.ReadFile(FilePath)
  local Contents = io.open(FilePath, "r"):read("*a")
  return Contents
end

-- Write contents to a file with a given path
function Helpers.WriteFile(FilePath, Contents)
  return io.open(FilePath, "w"):write(Contents)
end

-- Python-like string format function
function Helpers.StringFormat(String, ...)
  local Args = {...}
  
  local String = gsub(String, "{([\1-\124\126-\255]+)}", function(FormatValue)
    local Number = tonumber(FormatValue)
    if Number then
      local ArgValue = tostring(Args[Number + 1] or 'nil') 
      return ArgValue
    end
    return FormatValue
  end)

  return String
end

-- Error function with formatted error message
function Helpers.FormattedError(errorString, ...)
  return error(Helpers.StringFormat(errorString, ...))
end;

--
function Helpers.PrintAligned(Table)
  print(Helpers.AlignLines(Table))
end

function Helpers.PrintTable(Table, Spacing)
  return print(Helpers.StringifyTable(Table, Spacing))
end
--

-- Split strings to lines,
-- put the lines in a table
function Helpers.GetLines(String)
  local Lines = {}
  for Line in gmatch(String, "([\1-\9\11-\255]+)") do
    insert(Lines, Line)
  end
  return Lines
end

-- Unfortunately Lua won't let you access
-- individual characters by using MyString[2],
-- like in tables. This function fixes that 
function Helpers.StringToTable(String)
  local Table = {}
  local index = 1
  for Char in gmatch(String, ".") do
    Table[index] = Char
    index = index + 1
  end
  return Table
end

-- The same as the StringToTable() but
-- with more OOP
function Helpers.StringObject(String)
  local NewTable = Helpers.StringToTable(String)

  NewTable["Index"] = 1
  NewTable["Length"] = #NewTable
  NewTable["Current"] = NewTable[NewTable["Index"]]

  NewTable.Peek = function(Jump)
    NewTable["Index"] = NewTable["Index"] + (Jump or 1)
    local Value = NewTable[NewTable["Index"]]
    return Value
  end
  NewTable.Check = function(Jump)
    return NewTable[NewTable["Index"] + (Jump or 1)]
  end

  return NewTable
end

function Helpers.RangesToChars(...)
  local Characters = {}
  for i,v in pairs({...}) do
    local Min = (type(v[1]) == "number" and v[1]) or byte(v[1])
    local Max = (type(v[2]) == "number" and v[2]) or byte(v[2])
    for i = Min, Max do
      insert(Characters, char(i))
    end
  end
  return Characters
end

--* Experimental functions *--

-- Combine multiple tables and returns a function that retrieves a value based on the given key.
function Helpers.MergeTableGetters(...)
  local tables = {...}
  
  return function(_, key, ...)
    -- Iterate over each table in the merged tables.
    for _, tbl in ipairs(tables) do
      -- Check if the key exists in the current table.
      local value = tbl[key]
      if value then
        -- Return the value if found.
        return value
      end
    end
  end
end


function Helpers.SetNewProxy(methods)
  local proxy = newproxy(true)
  local proxy_mt = getmetatable(proxy)
  for index, value in pairs(methods) do
    proxy_mt[index] = value
  end
  
  return proxy
end

-- Function to create a table decorator with custom events
-- Really useful for debbuging purposes.
function Helpers.CreateTableDecorator(OriginalTable)
  -- Event pool to store callback functions for each event
  local EventPool = {
    Index = {};
    NewIndex = {};
    Call = {};
  }
  -- Hook table which replace entire methods 
  local Hooks = {}

  -- A function to execute all callback functions in a event pool
  local function ExecuteEventPool(EventName, ...)
    for Index, CallbackFunction in ipairs(EventPool[EventName]) do
      CallbackFunction(...)
    end
  end

  local BuiltinMethods = {}
  BuiltinMethods.__OriginalTable = OriginalTable
  BuiltinMethods.__EventPool = EventPool
  BuiltinMethods.__ExecuteEventPool = ExecuteEventPool

  -- A function to add a callback function to a event pool  
  function BuiltinMethods.__AddEvent(self, OnEvent, CallbackFunction)
    if not EventPool[OnEvent] then return end
    table.insert(EventPool[OnEvent], CallbackFunction)
  end;

  -- A function to completely replace a method with a custom function
  function BuiltinMethods.__AddHook(self, OnEvent, CallbackFunction)
    if not find("Index", "NewIndex", "Call", OnEvent) then return end
    Hooks[OnEvent] = CallbackFunction
  end;

  -- A custom proxy table which redirects all methods
  -- to an original table
  local MyProxy = Helpers.SetNewProxy({
    __index = function(self, index) 
      if BuiltinMethods[index] then
        return BuiltinMethods[index]
      elseif Hooks["Index"] then
        return Hooks["Index"](self, index)
      end

      ExecuteEventPool("Index", self, index)
      return OriginalTable[index]
    end;
    __newindex = function(self, index, value)
      if Hooks["NewIndex"] then
        return Hooks["NewIndex"](self, index, value)
      end

      ExecuteEventPool("NewIndex", self, index, value)
      OriginalTable[index] = value
    end;
    __call = function(self, ...)
      if Hooks["Call"] then
        return Hooks["Call"](self, ...)
      end

      ExecuteEventPool("Call", self, ...)
    end
  })

  return MyProxy
end

-- Return a read-only version of Table
function Helpers.MakeReadOnly(table, tableName)
  local newProxy = Helpers.SetNewProxy{
    __newindex = function(self, index, value)
      if tableName then
        -- Use tail-calls just because it doesn't add useless info to the stack
        return error(("Cannot change read-only index '%s' in table '%s'"):format(tostring(index), tableName))
      end;
      return error(("Cannot change read-only index '%s'"):format(tostring(index)))
    end;
    __index = function(self, index)
      return table[index]
    end;
  }

  return newProxy
end;

-- The same as "Helpers.MakeReadOnly", but it allows to add new values too.
--[[ Commented out because it's not needed at this moment
function Helpers.MakeAppendOnly(table, tableName)
  local newProxy = Helpers.SetNewProxy{
    __newindex = function(self, index, value)
      
    end;
  }
end;
-- ]]

-- Create a new class with the given base class
function Helpers.NewClass(baseClass)
  local function classConstructor(self, ...)
    -- Use a proxy instead of a metatable because it's lightier
    -- And doesn't store any data.
    local newClassInstance = newproxy(true)

    -- Set up metatable for the new class instance
    local classInstanceMt = getmetatable(newClassInstance)

    -- Get the super class and its raw table (if available)
    local superClass = baseClass.__super__
    local rawSuperClass = superClass and superClass.__raw__

    local sharedObjects = {}
    local classProperties = {};
    local newTable = {}

    -- Create a new read-only table to hold the special object properties
    classProperties = Helpers.MakeReadOnly{
      -- Provide an easy way to access anonymous super classes inside chzild classes
      __super__ = superClass and Helpers.SetNewProxy{
        __index = function(_, index)
          return rawSuperClass[index]
        end,
        __call = function(_, ...)
          return superClass.__init__(newClassInstance, ...)
        end
      };
      __shareObjects__ = function(self, ...)
        local objects = {...}
        for _, object in ipairs(objects) do 
          if not Helpers.TableFind(sharedObjects, object) then
            table.insert(sharedObjects, object)
          end;
        end
        classInstanceMt.__index = Helpers.MergeTableGetters(unpack(sharedObjects))    
      end;
      __raw__ = rawSuperClass
    }
 
    sharedObjects = {classProperties, newTable, baseClass, rawSuperClass}

    classInstanceMt.__index = Helpers.MergeTableGetters(unpack(sharedObjects))
    classInstanceMt.__newindex = function(_, index, value)
      if index == "__super__" then
        return error("Cannot modify the special key '__super__'")
      end
      newTable[index] = value
    end

    (baseClass.__init__ or function() end)(newClassInstance, ...)

    return newClassInstance
  end

  local returnClass =  Helpers.SetNewProxy{
    __call = classConstructor;
    __newindex = function(_, index, value)
      error("Cannot modify the class directly. Create an instance of the class to modify its properties.")
    end;
    __index = function(_, index)
      -- Provide access to the raw table of the class
      if index == "__raw__" then
        return baseClass
      elseif index == "__init__" then
        return baseClass[index] or function(self) end
      end

      local superClass = baseClass.__super__ or {}
      return baseClass[index] or superClass[index]
    end
  }

  return returnClass
end

function Helpers.ShareClasses(Class1, Class2)
  for i,v in pairs(Class2) do
    Class1[i] = v
  end
  return Class1
end

-- Change current string metatable to a custom one
function Helpers.CustomStringMt()
  local Mt = getmetatable("")

  local Tables = {}
  local function AddString(String)
    Tables[String] = Helpers.StringObject(String)
  end
  Mt.__index = function(self, index)
    if string[index] then
      return string[index]
    elseif not Tables[self] then
      AddString(self)
    end
    return Tables[self][index]
  end
  Mt.__newindex = function(self, index, value)
    if not Tables[self] then
      AddString(self)
    end
    Tables[self][index] = value
  end
  Mt.__tostring = function(self, ...)
    local Str = ""
    local Table = {}
    for i = self.Index, self.Length do
      local Value = self[i]
      if not Value then break end
      insert(Table, Value)
    end
    -- table.concat is much faster than anthing else
    return concat(Table, "")
  end
  return Mt
end

return Helpers