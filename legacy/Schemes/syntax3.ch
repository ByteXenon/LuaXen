# local function ParseSomething(CharStream)
#  %%{
#    @indent(spaces, 2)
#    @language(lua)
#    @char_stream(CharStream)
#
#    return {
#      <'1', "hello"> <'2', "something_ig"> {
#        '3' '2' {
#          '1' '2' '3'
#        }+
#      }?
#    }*
#  }%%
# end

@object "Parser:newSynthax()"

local_var_declr: {
  1
}

<local_var_declr, "help">?

{
  1 2 {
    1 2 {
      1 2 3 "4"
    }+
  }*
}?