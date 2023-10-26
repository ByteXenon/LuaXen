--[[
  Name: StandardLib.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/07/XX
--]]

local StdLib = {}

-- Factory function to create a new StdLib object
function StdLib.new()
    local stdLib = {}

    -- Private variables
    local _table = {}
    local _string = {}
    local _math = {}

    -- Private functions
    local function concat(...)
        return table.concat({...}, "\t")
    end

    local function pairs(Table)
        local index = 0
        return function(Table, Index) 
            index = (Index or 0) + 1

            return ((#Table >= index and index) or nil),
                   Table[index]
        end, Table
    end

    -- Public variables
    stdLib.table = _table
    stdLib.string = _string
    stdLib.math = _math

    -- Public functions
    function stdLib.string.concat(...)
        return concat(...)
    end

    function stdLib.table.pairs(Table)
        return pairs(Table)
    end

    function stdLib.math.max(...)
        return math.max(...)
    end

    function stdLib.math.min(...)
        return math.min(...)
    end

    function stdLib.print(...)
        return print(concat(...))
    end

    return stdLib
end

return StdLib.new()