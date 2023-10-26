# General information
@name "parser.lua"
@language "lua"

# Variables
local indentation = 0

# Define a token with name "expression" with 2 params of any type
# %0 = ReturnTable index
# %1 = Table inside of ReturnTable
# If %0 is nil, but  %1 is present it will just insert the token to the table.
# If %0 and %1 are nil, it will consume the token, but won't save it.
# Example: <expression, my_expression, expressions>
<expression, %0, %1> = {

    # Set custom operator precedence by changing the built-in "operator_precedence" option
    @operator_precedence = {
        {not, "NOT"} {and, "AND"} {or, "OR"} unary{-, "UNM"},
        {^, "POW"},
        {/, "DIV"} {*, "MUL"},
        {-, "MINUS"} {+, "PLUS"},
        {>, "MORE"} {>=, "MORE_OR_EQUAL"} {<, "LESS"} {<=, "LESS_OR_EQUAL"},
        {~=, "NOT_EQUAL"} {==, "EQUAL_EQUAL"}
    }

    # Use built-in expression logic
    @expression %0, %1
}

# Declare "for" statement parsing logic
for = {
    "for" <blank>+
    # Parse either the first group
    {
        # Group multiple tokens because the first token is always the statement
        # In this case the group is the statement
        {<keyword, iterator> <blank>* '='}

        <blank>* <expression, min> <blank>* ',' <blank>* <expression, max> <blank>* { ',' <blank>* <expression, step> <blank>* }?
    } |
    # ... Or the second, otherwise it will error.
    {
        (<keyword, _> -> Fields) <blank>* ({
            ',' <blank>* <keyword, _> <blank>*
        }* -> Fields)
        'in' <expression, expression> <blank>*
    }

    # "code_block" is the token type, the second argument "code_block" is the index in the table
    # to be stored.
    'do' <code_block, code_block> 'end'
}

# A rule for parsing "while" statement
while: {
    'while' <expression, expression> 'do'
        <code_block, code_block>
    "end"
}

# A rule for parsing "repeat" statement
repeat: {
    'repeat'
        <code_block, code_block>
    'until' <expression, expression>
}

# A rule for parsing "if" statement
if: {
    'if' <expression, expression> 'then'
        <code_block, code_block>
        ({
            ({
                'elseif' <expression, expression> 'then' <code_block, code_block>
            } -> _)
        }* -> ElseIfs)
        ({
            'else' <code_block, code_block>
        }? -> Else)
    'end'
}

# A rule for parsing all variable declarations
var_declr: {
    (
        <keyword, _>* -> Variables
    ) <blank>* '=' (
        <expression, _>* -> Expressions
    )
}

local_var_declr: {
    "local" _+ var_declr
}

# The main (fallback) function
#__main__: {
#    # Make a new AST table and use it for tokens
#    # Later that table would be inserted to a global return table
#    # "-> _" means put matches in a new AST table.
#    { for | if | repeat | local_var_declr | var_declr }* -> _
#}

# Define a token to match spaces at the beginning of a line
indent: {
    # Match any number of spaces at the beginning of a line
    # The "^" symbol denotes the beginning of a line
    # The "*" symbol denotes "zero or more" of the preceding element
    # The "+" symbol denotes "one or more" of the preceding element
    # The "->" symbol is used to assign the matched spaces to the "level" variable
    # The "len" function is used to count the number of spaces
    ^%sindentation+
}

# Modify the main function to use the "indent" token
code_block: {
    # Match the "indent" token at the beginning of each line
    # The "-> _" symbol is used to put matches in a new AST table
    { indent (for | if | repeat | local_var_declr | var_declr) }* -> _
}

code_block