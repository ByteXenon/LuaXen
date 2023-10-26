--[[
  Name: Main.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

-- NOTE: This module doesn't work, don't even try
--* Libraries *--
local Helpers = require("Helpers/Helpers")

--* Library object *--
local Visual = {}

--* Functions *--

function Visual.ExpressionTree(Tokens)
  local Lines = {}

  local Draw
  function Draw(Line, Position, Text)
    if not Lines[Line] then
      Lines[Line] = {}
    end
    table.insert(Lines[Line], {Position, Text})
  end
  local Output
  function Output()
    local String = ""
    for Index,Table in pairs(Lines) do
      local Line = ""
      for Index2, Table2 in pairs(Table) do
        local NewIndetication = (Table2[1]) - #Line
         Line = Line..string.rep(" ", NewIndetication)..Table2[2]
      end
      String = String .. "\n" .. Line
    end
    return String
  end
  local NewExpression;
  function NewExpression(Table, Line, Depth, Side)
    if Table["TYPE"] ~= "Expression" then 
      -- Just a number
      Draw(Line, Depth, Table[2])
      return
    end
    local Depth = Depth or 40
    local Line = Line or 1
    local Side = Side or 0

    local Left = Table[1]
    local Operator = Table[2][1]
    local Right = Table[3]

    Draw(Line, Depth, Operator)
    Draw(Line + 1, (Depth) - 1, "/")
    Draw(Line + 1, (Depth) + #Operator, "\\")
    NewExpression(Left, Line + 2, (Depth) - 3 + Side, 0)
    NewExpression(Right, Line + 2, (Depth) + 4 + Side, 2)
  
    return Output()
  end
  return NewExpression(Tokens)
end

return Visual
