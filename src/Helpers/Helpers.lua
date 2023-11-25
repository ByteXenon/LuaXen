--[[
  Name: Helpers.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX
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
local unpack = (unpack or table.unpack)

--* Library object *--
local Helpers = {}

--- Inverts the keys and values of a table.
-- @param table inputTable The table to invert.
-- @return table The inverted table.
function Helpers.InvertTableKeyValue(inputTable)
  assert(type(inputTable) == "table", "inputTable must be a table")

  local newTable = {}
  for index, value in pairs(inputTable) do
    newTable[value] = index
  end

  return newTable
end

--- Reverses the order of elements in a numeric indexed table.
-- @param table inputTable The table to reverse.
-- @return table The reversed table.
function Helpers.ReverseNumericTable(inputTable)
  assert(type(inputTable) == "table", "inputTable must be a table")

  local newTable = {}
  for index = 1, #inputTable, 1 do
    local value = inputTable[index]
    newTable[#inputTable - index + 1] = value
  end
  return newTable
end

--- Merges values from table2 to table1.
-- @param table table1 The table to merge into.
-- @param table table2 The table to merge from.
function Helpers.MergeTable(table1, table2)
  assert(type(table1) == "table", "table1 must be a table")
  assert(type(table2) == "table", "table2 must be a table")

  for _, value in ipairs(table2) do
    insert(table1, value)
  end
end

--- Finds a value in a table.
-- @param table Table The table to search.
-- @param Value The value to search for.
-- @return number|nil The index of the value in the table, or nil if not found.
function Helpers.TableFind(Table, Value)
  assert(type(Table) == "table", "Table must be a table")

  for Index, TableValue in pairs(Table) do
    if Value == TableValue then
      return Index
    end
  end
  return nil
end

--- Gets multiple elements from a table and inserts them into another table.
-- @param table Table The table to get elements from.
-- @param number min The minimum index to get.
-- @param number max The maximum index to get.
-- @return table The table containing the elements.
function Helpers.GetTableElementsFromTo(Table, min, max)
  assert(type(Table) == "table", "Table must be a table")
  assert(type(min) == "number", "min must be a number")
  assert(type(max) == "number", "max must be a number")

  local tb = {}
  for i = min, max do
    insert(tb, Table[i])
  end
  return tb
end

--- Clones a table and all values in it.
-- @param table Table The table to clone.
-- @return table The cloned table.
function Helpers.TableClone(Table)
  assert(type(Table) == "table", "Table must be a table")

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

--- Finds Table1 indices in stream of Table2 values, with the higher priority for more lengthy values.
-- @param table Table1 The table containing the indices to search for.
-- @param table Table2 The table containing the values to search in.
-- @param number Table2Index The starting index in Table2.
-- @return string|nil The best match found in Table2, or nil if no match found.
function Helpers.TableIndexSearch(Table1, Table2, Table2Index)
  assert(type(Table1) == "table", "Table1 must be a table")
  assert(type(Table2) == "table", "Table2 must be a table")
  assert(type(Table2Index) == "number", "Table2Index must be a number")

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

--- Gets the length of a table.
-- @param table Table The table to get the length of.
-- @return number The length of the table.
function Helpers.TableLen(Table)
  assert(type(Table) == "table", "Table must be a table")

  local TableLength = 0
  for Index, Value in pairs(Table) do
    TableLength = TableLength + 1
  end
  return TableLength
end

--- Clears all elements of a table without copying it.
-- @param table Table The table to clear.
-- @return table The cleared table.
function Helpers.ClearTable(Table)
  assert(type(Table) == "table", "Table must be a table")

  for Index, _ in pairs(Table) do
    Table[Index] = nil
  end
  return Table
end

--- Copies first-level values from Table1 to Table2.
-- @param table Table1 The table to copy from.
-- @param table Table2 The table to copy to.
-- @return table The table containing the copied values.
function Helpers.CopyTableElements(Table1, Table2)
  assert(type(Table1) == "table", "Table1 must be a table")
  assert(type(Table2) == "table", "Table2 must be a table")

  for Index, Value in pairs(Table1) do
    Table2[Index] = Value
  end
  return Table2
end

--- Converts a table to a string, recursively.
-- @param table Table The table to convert.
-- @param[opt=2] number Spacing The number of spaces to use for indentation.
-- @return string The string representation of the table.
function Helpers.StringifyTable(Table, Spacing)
  assert(type(Table) == "table", "Table must be a table")

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

--- Serializes a value to a string.
-- @param Value The value to serialize.
-- @return string The serialized value.
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

--- Converts a table to a pretty string.
-- @param table tableData The table to convert.
-- @return string The pretty string representation of the table.
function Helpers.TableToPrettyString(tableData)
  assert(type(tableData) == "table", "tableData must be a table")

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

--- Recursively compares two tables.
-- @param table Table The first table to compare.
-- @param table ... The other tables to compare.
-- @return boolean Whether the tables are equal.
function Helpers.TablesEqual(Table, ...)
  assert(type(Table) == "table", "Table must be a table")
  
  local Tables = {...}
  local function CheckValue(Table1, Table2, Index)
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

--- Reads a file from a given path.
-- @param string FilePath The path of the file to read.
-- @return string The contents of the file.
function Helpers.ReadFile(FilePath)
  assert(type(FilePath) == "string", "FilePath must be a string")

  local Contents = io.open(FilePath, "r"):read("*a")
  return Contents
end

--- Writes contents to a file with a given path.
-- @param string FilePath The path of the file to write to.
-- @param string Contents The contents to write to the file.
function Helpers.WriteFile(FilePath, Contents)
  assert(type(FilePath) == "string", "FilePath must be a string")
  assert(type(Contents) == "string", "Contents must be a string")

  return io.open(FilePath, "w"):write(Contents)
end

--- Formats a string with given arguments.
-- @param string String The string to format.
-- @param ... The arguments to format the string with.
-- @return string The formatted string.
function Helpers.StringFormat(String, ...)
  assert(type(String) == "string", "String must be a string")

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

--- DEPRECATED: Throws an error with a formatted error message.
-- @param string errorString The error message to format.
-- @param ... The arguments to format the error message with.
function Helpers.FormattedError(errorString, ...)
  error(Helpers.StringFormat(errorString, ...))
end;

--- Prints a table with aligned columns.
-- @param table Table The table to print.
function Helpers.PrintAligned(Table)
  assert(type(Table) == "table", "Table must be a table")

  print(Helpers.AlignLines(Table))
end

--- Converts a table to a string with a given spacing.
-- @param table Table The table to convert.
-- @param? number Spacing The spacing between columns.
-- @return string The string representation of the table.
function Helpers.PrintTable(Table, Spacing)
  assert(type(Table) == "table", "Table must be a table")

  return print(Helpers.StringifyTable(Table, Spacing))
end

--- Splits a string into lines and puts them in a table.
-- @param string String The string to split.
-- @return table The table of lines.
function Helpers.GetLines(String)
  assert(type(String) == "string", "String must be a string")

  local Lines = {}
  for Line in gmatch(String, "([\1-\9\11-\255]+)") do
    insert(Lines, Line)
  end
  return Lines
end

--- Converts a string to a table of characters.
-- @param string String The string to convert.
-- @return table The table of characters.
function Helpers.StringToTable(String)
  assert(type(String) == "string", "String must be a string")

  local Table = {}
  local index = 1
  for Char in gmatch(String, ".") do
    Table[index] = Char
    index = index + 1
  end
  return Table
end

--- Creates a string object with additional methods.
-- @param string String The string to convert to a string object.
-- @return table The string object.
function Helpers.StringObject(String)
  assert(type(String) == "string", "String must be a string")

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

--- Converts a range of characters to a table of characters.
-- @param ... The ranges of characters to convert.
-- @return table The table of characters.
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