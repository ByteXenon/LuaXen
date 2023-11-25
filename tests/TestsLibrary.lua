--* TestsLibrary *--
local TestsLibrary = {} 

function TestsLibrary.tablesEqual(table1, table2)
  for _, tb in ipairs({table1, table2}) do
    for index in pairs(tb) do
      local val1, val2 = table1[index], table2[index]
      if type(val1) == "table" and type(val2) == "table" then
        local areEqual = TestsLibrary.tablesEqual(val1, val2)
        if not areEqual then return false end
      end
      if val1 ~= val2 then return false end
    end
  end
  return true
end


return TestsLibrary