local ASTBuilder = require("ASTBuilder/ASTBuilder")

ASTBuilder:BuildAST():Group(
  IfStatement("1+2 == 3", CodeBlock("MathIsNotBroken"))
)