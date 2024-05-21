# Contribution Guidelines

Thank you for your interest in contributing to this project! All contributions are welcome, even if you have limited knowledge of Lua. If you encounter any issues, feel free to open an issue and we will assist you or make the necessary changes ourselves. However, if you are familiar with Lua and would like to contribute, please take a moment to review the following guidelines.

## Table of Contents
- [Contribution Guidelines](#contribution-guidelines)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
  - [Code Style](#code-style)
  - [Coordination](#coordination)
  - [License](#license)

## Getting Started
To get started with contributing, follow these steps:
1. Fork the repository.
2. Clone the forked repository to your local machine.
3. Install the necessary dependencies.
4. Make your changes and test them thoroughly.
5. Commit your changes and push them to your forked repository.
6. Submit a pull request.

## Code Style
Please adhere to the following code style guidelines:
- Use consistent indentation. This project uses 2 spaces for indentation, no tabs, and no trailing whitespace.
- Follow naming conventions. Use `camelCase` for variables and functions, and `PascalCase` for classes.
- Write clear and concise comments. If you are writing a comment for a function, use the following format:
```lua
--- This is a LuaDoc-style comment.
-- @param param1 A short description of the first parameter.
-- @param param2 A short description of the second parameter.
-- @return A short description of the return value.
function myFunction(param1, param2)
  -- ...
end

--- This is another LuaDoc-style comment.
function table:myMethod()
  print(self.value)
end
```
- Use meaningful variable and function names. Avoid using abbreviations, unless they are well-known (e.g. `AST`, etc.)

## Coordination
Do you have any questions or concerns? Feel free to email me at: `ddavi142(at)asu.edu` or add me on Discord: `bytexenon_was_taken`.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.