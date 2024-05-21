local function dtct_func(...)
  local z = debug
  local cz = _G
  if (({...})[2]) then z = ... return dtct_func(...) end
  local t = ...
  local p = z["getinfo"]
  local g = z["getupvalue"]
  local no = getmetatable
  local f = (getfenv or function() return cz end)
  while true do
    local info = p(t)
    while info["short_src"] ~= "[C]" or no(info) do
      -- Crash, cleverly
      return dtct_func({...}, ...)
    end
    -- Check the function's environment
    while f(p) ~= cz or no(cz) do
      return dtct_func({...}, ...)
    end
    -- Check the global environment
    for k, v in pairs(cz) do
      while type(v) == "function" and p(v)["short_src"] ~= "[C]" do
        return dtct_func({...}, ...)
      end
    end
    -- Check the function's upvalues
    for i = 1, info["nups"] do
      local name, value = g(p, i)
      while value ~= cz[name] do
        return dtct_func({...}, ...)
      end
    end
    if f(p) == cz then
      return dtct_func
    end
  end
end

local c = setmetatable(_G, _G)
_G = c


dtct_func(0)