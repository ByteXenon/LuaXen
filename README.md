# LuaXen

LuaXen is a toolkit for Lua programming language. It provides functionalities for Lua code compiling, (de)obfuscating, minifying, beautifying and much more. This project is a collaborative effort led by Luna, with contributions from Evan, DT, and others.

The project is built from scratch without any third-party libraries. All modules are designed to be as simple and follow as much good code practices as possible.

## Table of Contents:
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

## Roadmap

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

## Changelog

### Beta 1.10 - "The calm before the storm"

- **Added LuaTransformer and SyntaxHighlighter modules**: These new modules can transform Lua code to a different version and highlight Lua code, respectively. 
- **Boosted all Lua Interpreter related modules**: We're on the brink of reaching the [self-hosting](https://en.wikipedia.org/wiki/Self-hosting_(compilers)) stage, and we're upgrading all modules related to the Lua Interpreter to get there.
- **Put the Decompiler/ASTHierarchy modules on a temporary hiatus**: We're rewriting the Decompiler/ASTHierarchy modules module to follow as many good code practices as possible. They're completely broken in this version, due to heavily relying on AST nodes
- **Revamped ASTExecutor from the ground up**: The ASTExecutor module has been completely rewritten for efficiency and ease of use. We're planning to make the entire project follow the new ASTExecutor's code style.
- **Brought ASTExecutor to 99% completion**: We're working on the last 1% of the module, which involves fixing an Interpreter bug that incorrectly places index operators after logical statements.
- **Initiated a complete project rewrite**: We're making massive changes to make the project as readable and easy to understand as possible. This is our second priority, right after making the project work as intended.
- **& Much more**: This version has changed a lot of parts of the project, it's difficult to list them all here, so we recommend you to check out the code yourself. 
- **What's next?** - We have big plans for this project and we're not stopping here. Upcoming features include:
  - **A fully functional decompiler**: We're rewriting the decompiler to improve its code quality.
  - **Deobfuscator/Obfuscator**: We arleady have private prototypes of these modules, but we're planning to make them public soon.
  - **99% functional instruction Generator**: We're rewriting this too, despite it working almost fine in its current state.

And lastly, before this project gets too big and popular, I, Luna, would like to thank everyone who has contributed to this project so far. I'm grateful for DTSadded for helping me with the compiler theory, Evan for helping me with the project's code, and dibyendumajumdar for the wonderful [documentation](https://the-ravi-programming-language.readthedocs.io/en/latest/index.html) of Lua VM instructions, which helped me a lot in the first stages of this project.

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
