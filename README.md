# LuaXen - A Lua code transformation toolkit

> An elegant Lua toolkit for transforming, compiling, obfuscating, etc. Lua(u/JIT) code of any version.

![Lua](https://img.shields.io/badge/Lua-5.1%2C%205.2%2C%205.3%2C%205.4-blue?style=for-the-badge&logo=lua)
![GitHub stars](https://img.shields.io/github/stars/ByteXenon/LuaXen?style=for-the-badge)
![License](https://img.shields.io/github/license/ByteXenon/LuaXen?style=for-the-badge)
![GitHub last commit](https://img.shields.io/github/last-commit/ByteXenon/LuaXen?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/ByteXenon/LuaXen?style=for-the-badge)

LuaXen is a toolkit for the Lua programming language, made in Lua itself. It's got a bunch of features for working with Lua code, like compiling, (de)obfuscating, minifying, beautifying, and a whole lot more.
This project doesn't use complex Lua functionality (e.g metatables, goto, etc.), so it's compatible with all versions of Lua, including LuaJIT and Roblox Luau.

## Table of Contents:
- **[LuaXen](#luaxen---a-lua-toolkit)**
  - **[Table of Contents](#table-of-contents)**
  - **[Features](#features)**
  - **[Roadmap](#roadmap)**
  - **[Installation & Usage](#installation--usage)**
  - **[Changelog](#changelog)**
  - **[FAQ](#faq)**
  - - **[What is the purpose of this project?](#what-is-the-purpose-of-this-project)**
  - - **[What is the license of the generated/transformed code?](#what-is-the-license-of-the-generatedtransformed-code)**
  - - **[What is the current status of this project?](#what-is-the-current-status-of-this-project)**
  - - **[Can I contribute?](#can-i-contribute)**
  - - **[Can I use this project in my own project?](#can-i-use-this-project-in-my-own-project)**

**Quick Links:** **[API Source](./src/api.lua)** | **[Changelog](./CHANGELOG.md)** | **[License](./LICENSE)** | **[Contributing](./CONTRIBUTING.md)** | **[Usage Guidelines](./USAGE_GUIDELINES.md)**

## Features

This project includes the following features:

- **Pseudo-Assembler for Lua Bytecode:** A tool for turning pseudo-assembly code into Lua bytecode.
- **Parser:** A powerful parser for turning Lua code into abstract syntax trees.
- **Compiler:** A compiler for turning Lua code into bytecode, which later can be optimized and executed.
- **Flexible Virtual Machine:** A virtual machine to execute Lua bytecode.
- **ASTExecutor:** A module for executing abstract syntax trees without the need for a virtual machine or an instruction generator.
- **Code Beautifier and Minifier:** Tools for making your Lua code as readable or as compact as you need.
- **Packer:** A tool for packing Lua code into a single file.
- **Optimizer:** An optimizer for improving the performance of your Lua code.
- **Obfuscator:** A custom-made obfuscator that makes your code harder to read and reverse-engineer.

Did we mention that all of this is completely free and open-source?
If that made you interested, you can check out the [installation instructions](#installation--usage) below, or you can find some examples of how to use different modules in the `/examples` directory.

## Roadmap

We have big plans for the future of the Lua Compiler project:

**Improvements:**

- Decompiler
- Static Analyzer

**New Features:**

- Documentation
- *Working* Deobfuscator
- - SynapseXen deobfuscator
- Code profiler
- Code smell detector
- Luau-Lua transpiler
- VM-based Full-Code Obfuscator
- Logic-based Full-Code Obfuscator

## Installation & Usage

To run the code, you will need to install Lua 5.1 or a higher version.

Follow these steps to get started:

1. Clone the repository:

```bash
git clone https://github.com/ByteXenon/LuaXen
cd LuaXen
```

2. Install LuaXen for the supported Lua versions:

```bash
sudo make install
```

3. Start using LuaXen in your Lua scripts

### Example Usage

To imitate the behavior of the "loadstring" function using LuaXen, you can use the following code:

```lua
local LuaXen = require("LuaXen")

LuaXen.VirtualMachine.Execute("print('Hello, world!')")
```

It effectively tokenizes, parses, converts to bytecode, and executes the given Lua code inside the LuaXen virtual machine.

Want to beautify your Lua code? Use the following code:

```lua
local LuaXen = require("LuaXen")

local badCode = "local function foo() print('Hello, world!') end"
local beautifiedCode = LuaXen.Beautifier.Beautify(badCode)

print(beautifiedCode)
```

For a complete list of examples, refer to the [examples](./examples) directory, or check out the [API source](./src/api.lua) for more information (it's simple, we promise).

## Changelog

Read the [CHANGELOG.md](./CHANGELOG.md) file for more information.

## FAQ

### What is the purpose of this project?

LuaXen aims to provide a comprehensive set of functionalities for transforming, compiling, (de)obfuscating, and optimizing Lua code. We want to make it easier for developers to work with Lua code, regardless of the version they're using.

This project is built as one giant toolkit (just like GCC), with each module serving a different purpose, making it easier for the modules to work together, all of them can be chained together to achieve a specific goal, be it beautifying, compiling, or obfuscating Lua code.

### How does it work?

It really depends on how you're using it, but in general, LuaXen operates by processing your Lua code through a series of transformations, each corresponding to the module you're utilizing. For instance, if your goal is to beautify your code, LuaXen will dissect your code into tokens, parse it, and then reconstruct it in a more readable format following built-in beautification rules. This process is similar for other modules, such as the compiler, obfuscator, and more.

### What is the license of the generated/transformed code?

The license of the whatever output you get from this project is the same as the input code. If you input code that is licensed under the MIT license, the output will also be licensed under (your) MIT license. The transformation process does not affect the license of the code in any way.

### What is the current status of this project?

The project is currently in beta and is not yet ready for production use. We're actively working on it, but it will take some time to reach a stable release. Additionally, sometimes, the project may not be updated for a while, but I (as ByteXenon, the original author of the project) will always make sure to come back to it and update it when I can.

### Can I contribute?

Absolutely! We're always looking for new contributors. Feel free to fork this project and submit a pull request. We'll review it as soon as we can.

### Can I use this project in my own project?

Yes, you are welcome to use this project in your own work. You can use it as you see fit, provided you give appropriate credit and adhere to the terms of this project's [MIT license](./LICENSE).