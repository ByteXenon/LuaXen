--[[
  Name: TestsHelpers.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Export library functions *--
local unpack = (unpack or table.unpack)
local insert = table.insert
local concat = table.concat
local rep = string.rep

--* Local functions *--
local TestsHelpers = {}

-- Helper function to check if two tables are equal
function TestsHelpers.tablesEqual(table1, table2)
  local checkedIndices = {}
  for _, tbl in ipairs({table1, table2}) do
    for index, value in pairs(tbl) do
      if not checkedIndices[index] then
        checkedIndices[index] = true
        -- If values are not equal and not tables, return false
        if table1[index] ~= table2[index] and type(value) ~= "table" then return false end
        -- If values are tables, recursively check for equality
        if type(value) == "table" and not TestsHelpers.tablesEqual(table1[index], table2[index]) then return false end
      end
    end
  end
  return true
end

-- Function to get differences between two tables
function TestsHelpers.getTableDifferences(actual, expected)
  local differences = {}
  local areDifferent = false

  -- Check for differences in expected keys
  for key, value in pairs(expected) do
    local actualValue = actual[key]
    if value ~= "<any>" and actualValue ~= value then
      if value == "<any...>" then return differences end
      -- If value and actualValue are a table,
      -- get table differences using getTableDifferences function
      if type(value) == "table" and type(actualValue) == "table" then
        local actualAndRealValueDifferences = TestsHelpers.getTableDifferences(actualValue, value)
        if actualAndRealValueDifferences.areDifferent then
          areDifferent = true
        end
        insert(differences, {
          index = key,
          actual = actualValue,
          expected = value,
          differences = actualAndRealValueDifferences
        })
      else
        areDifferent = true
        insert(differences, {index = key, actual = actualValue, expected = value})
      end
    end
  end

  -- Check for keys present in actual but not in expected
  for key, value in pairs(actual) do
    if value == nil then
      insert(differences, {index = key, actual = value, expected = nil})
    end
  end

  differences.areDifferent = areDifferent
  return differences
end

-- Function to print differences between two tables
function TestsHelpers.printTableDifferences(differences)
  TestsHelpers.printTable(differences)
  -- Get the differences
  -- local differences = TestsHelpers.getTableDifferences(actual, expected)

  -- Function to print differences recursively
  local function printDifferences(diffs, prefix)
    for _, diff in ipairs(diffs) do
      local index = TestsHelpers.serializeValue(diff.index)
      local actual = diff.actual
      local expected = diff.expected

      -- If 'actual' is a table, it means there are nested differences
      if diff.differences and #diff.differences ~= 0 then
        print(prefix .. "[" .. index .. "] has nested differences:")
        printDifferences(diff.differences, prefix .. "  ")
      elseif not diff.differences and actual ~= expected then
        actual = TestsHelpers.serializeValue(actual)
        expected = TestsHelpers.serializeValue(expected)
        print(prefix .. "[".. index .. "]: actual = " .. tostring(actual) .. ", expected = " .. tostring(expected))
      end
    end
  end

  -- Start printing differences
  print("Differences:")
  printDifferences(differences, "  ")
end

-- Convert a table to a string, recursively
function TestsHelpers.stringifyTable(Table, Spacing)
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

  return "{\n" .. VisitTable(Table, 1) .. "\n" .. "}"
end

-- Serialize a value to a string
function TestsHelpers.serializeValue(value)
  local value = value
  local valueType = type(value)

  if valueType == "string" then
    return "'" .. value .. "'"
  elseif valueType == "table" then
    return TestsHelpers.stringifyTable(value, 4)
  else
    return tostring(value)
  end
end

function TestsHelpers.printTable(Table, Spacing)
  return print(TestsHelpers.stringifyTable(Table, Spacing))
end

return TestsHelpers