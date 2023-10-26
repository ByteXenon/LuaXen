--[[
  Name: Templates.lua
  Author: ByteXenon [Luna Gilbert]
  Approximate date of creation: 2023/06/XX
--]]

local Templates = { 
  Token  = (
    "{0}{1}(self, {2}, {3}, {4})"
  );
  KnownToken  = (
    "{0}self:{1}({2}, {3}, {4})"
  );
  Keyword = (
    "{0}self:Keyword({1})"
  );
  String = (
    "{0}self:Keyword({1})"
  );

  ZeroOrMore = (
    "{0}self:ZeroOrMore("
    .. "\n{0}  ,function(self)"
    .. "\n{1}"  -- Value
    .. "\n{0}  end"
    .. "\n{0}  ,function(self)"
    .. "\n{2}" -- Statement
    .. "\n{0}  end"
    .. "\n{0})"
  );
  ZeroOrOne = (
    "{0}self:ZeroOrOne("
    .. "\n{0}  ,function(self)"
    .. "\n{1}"  -- Value
    .. "\n{0}  end"
    .. "\n{0}  ,function(self)"
    .. "\n{2}"  -- Statement
    .. "\n{0}  end"
    .. "\n{0})"
  );
  OneOrMore = (
    "{0}self:OneOrMore("
    .. "\n{0}  ,function(self)"
    .. "\n{1}"  -- Value
    .. "\n{0}  end"
    .. "\n{0}  ,function(self)"
    .. "\n{2}"  -- Statement
    .. "\n{0}  end"
    .. "\n{0})"
  );
  
  SyntaxDeclaration = (
    "\n{0}local {1};"
    .. "\n{0}local function {1}(self)"
    .. "\n{2}"
    .. "\n{0}end\n"
  );
  IfTemplate = (
    "{0}self:IF("
    .. "\n{0}  function(self)"
    .. "\n{1}"  -- Value
    .. "\n{0}  end"
    .. "\n{0}  , function(self)"
    .. "\n{2}" -- Statement
    .. "\n{0}  end"
    .. "\n{0})"
  )
}

return Templates