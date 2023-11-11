# LuaXen

LuaXen is a toolkit for Lua programming language. It provides functionalities for Lua code compiling, (de)obfuscating, minifying, beautifying and much more. This project is a collaborative effort led by Luna, with contributions from Evan, DT, and others.

The project is built from scratch without any third-party libraries. All modules are designed to be as simple and follow as much good code practices as possible.

## Table of Contents:
=======
- **[Features](#features)**
- **[Roadmap](#roadmap)**
- **[Getting Started](#getting-started)**
- **[Changelog](#changelog)**
- - **[Beta 1.09](#beta-109---re-animation-of-the-dead-code) - "*RE-ANIMATION OF THE DEAD (code)!*"**
- - **[Beta 1.08](#beta-108---the-humble-beginnings) - "*\~\~\~The humble beginnings\~\~\~*"**
- **[FAQ](#faq)**

## Features

This project includes the following features:

- **Pseudo-Assembler for Lua Bytecode:** A tool for turning pseudo-assembly to Lua bytecode.
- **Interpreter:** A near-complete interpreter featuring a tokenizer, parser, and math parser.
- **Flexible Virtual Machine:** A virtual machine designed for flexibility and ease of use.
- **Code Beautifier and Minifier:** Tools for making your Lua code as readable or as compact as you need.
- **Optimizer:** An optimizer for improving the performance of your Lua code (currently under development).
- **ASTExecutor and Obfuscator:** Tools for executing abstract syntax trees and obfuscating code.
- **ASTHierarchy Module:** A module for better AST navigation.
  **API:** An API designed to connect all modules together and make it easier to work with them.

You can find some examples how to use different modules in the `/examples` directory.

## 📝 Changelog

### Beta 1.09 - "RE-ANIMATION OF THE DEAD (code)!"

- **Refactored the file structure**: Looked at the project's monstrosity and decided to make the file directory look much better now.
- **Released the legacy files**: You can explore our (mainly Luna's) previous attempts to make a Lua compiler in the `/legacy` directory.
- **\~HELLISH DECOMPILER\~**: Got the latest version of the decompiler from the bowels of hell, it shouldn't work, but it works, nobody knows how.
- **Rewrote the assembler**: Previous assembler was too weak to handle this project's massive weight, all hail the lean & clean new Assembler!
- **Added more examples**: Magically added more API/general examples, feel free to explore them in the new `/examples` directory.
- **Upgraded UNIT tests core**: Added more tests, because more test coverage normally doesn't make things any worse, right?!
- **Luau support plans**: We're actively discussing how to add Roblox Luau support on our Discord GCs, get ready for something fresh!
- **Code deobfuscation support plans**: We've been discussing how to automatically break through VMs of Lua obfuscators and dump their instructions lately, it will be a huge task, but we'll try.

### Beta 1.08 - "\~\~\~The humble beginnings\~\~\~"

- **Added Changelog**: Are you surprised? - We're not, you're much welcome to read our genius jokes in the changelog. :-)
- **Rolled out some basic unit tests**: Bug elimination is our full-time job now.
- **Cleaned up whitespace**: Went on a little cleaning spree and removed trailing spaces in some files.
- **Fixed AST to Instructions bug**: Fixed an annoying bug that was messing with the conversion of some Abstract Syntax Tree (AST) nodes to instructions. It should behave now (:<
- **Enhanced VM Debugging**: Beefed up the Virtual Machine with more debugging support.
- **Enabled API Debugging**: The API can now flex its muscles with VM debugging support.

## 🗺️ Roadmap

We have big plans for the future of the Lua Compiler project:

**Improvements:**

- Interpreter
- Decompiler
- Static Analyzer
- Instruction Generator

**New Features:**

- *Working* Deobfuscator
- SynapseXen deobfuscator
- Code profiler
- Code smell detector
- Luau-Lua transpiler
- Lua 5.2+ syntax support
- VM-based Full-Code Obfuscator
- Logic-based Full-Code Obfuscator

## Getting Started

To run the code, you need to install Lua 5.1 or higher.

## ❓ FAQ

**What is the purpose of this project?**

This project aims to transform/compile Lua(u) code of any version. It started as a hobby but has potential for future expansion.
=======
## Changelog

### Beta 1.09 - "RE-ANIMATION OF THE DEAD (code)!"

- **Refactored the file structure**: Looked at the project's monstrosity and decided to make the file directory look much better now.
- **Released the legacy files**: You can explore our (mainly Luna's) previous attempts to make a Lua compiler in the `/legacy` directory.
- **\~HELLISH DECOMPILER\~**: Got the latest version of the decompiler from the bowels of hell, it shouldn't work, but it works, nobody knows how.
- **Rewrote the assembler**: Previous assembler was too weak to handle this project's massive weight, all hail the lean & clean new Assembler!
- **Added more examples**: Magically added more API/general examples, feel free to explore them in the new `/examples` directory.
- **Upgraded UNIT tests core**: Added more tests, because more test coverage normally doesn't make things any worse, right?!
- **Luau support plans**: We're actively discussing how to add Roblox Luau support on our Discord GCs, get ready for something fresh!
- **Code deobfuscation support plans**: We've been discussing how to automatically break through VMs of Lua obfuscators and dump their instructions lately, it will be a huge task, but we'll try.

### Beta 1.08 - "\~\~\~The humble beginnings\~\~\~"

- **Added Changelog**: Are you surprised? - We're not, you're much welcome to read our genius jokes in the changelog. :-)
- **Rolled out some basic unit tests**: Bug elimination is our full-time job now.
- **Cleaned up whitespace**: Went on a little cleaning spree and removed trailing spaces in some files.
- **Fixed AST to Instructions bug**: Fixed an annoying bug that was messing with the conversion of some Abstract Syntax Tree (AST) nodes to instructions. It should behave now (:<
- **Enhanced VM Debugging**: Beefed up the Virtual Machine with more debugging support.
- **Enabled API Debugging**: The API can now flex its muscles with VM debugging support.

## FAQ

**What is the purpose of this project?**

This project aims to transform/compile Lua(u) code of any version. It started as a hobby but has potential for future expansion.
