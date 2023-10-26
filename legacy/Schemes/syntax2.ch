# General information
@name "parser.lua"
@language "lua"


# If %0 is nil, but  %1 is present it will just insert the token to the table.
# If %0 and %1 are nil, it will consume the token, but won't save it.
expression: {

    # Set custom operator precedence by changing the built-in "operator_precedence" option
    @operator_precedence.not = "NOT" {
        { 'not', "NOT" } { 'and', "AND" } { 'or', "OR" } unary{ '-', "UNM" },
        { '^', "POW" },
        { '/', "DIV" } { '*', "MUL" },
        { '-', "MINUS" } { '+', "PLUS" },
        { '>' , "MORE" } { '>=' , "MORE_OR_EQUAL" } { '<' , "LESS" } { '<=' , "LESS_OR_EQUAL" },
        { '~=', "NOT_EQUAL" } { '==', "EQUAL_EQUAL" }
    }

    # Use built-in expression logic
    @expression %1, %2
}

# Declare "for" statement parsing logic
for: {
    "for" <blank>+
    
    # Parse either the first group
    {
        # Group multiple tokens because the first token is always the statement
        # In this case the group is the statement
        {<keyword, iterator> <blank>* '='}

        <blank>* <expression, min> <blank>* ',' <blank>* <expression, max> <blank>* { ',' <blank>* <expression, step> <blank>* }?
    } | {
        (<keyword, _> -> Fields) <blank>* ({
            ',' <blank>* <keyword, _> <blank>*
        }* -> Fields)

        'in' <expression, expression> <blank>*
    }

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
    "local" _+ <var_declr>
}


# Modify the main function to use the "indent" token
code_block: {
    {
        <for, _> | <if, _> | <repeat, _> | <local_var_declr, _> | <var_declr, _>
    }*
}

<code_block>