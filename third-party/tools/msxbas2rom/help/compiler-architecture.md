# Compiler Architecture

> MSXBAS2ROM was designed to transform MSX BASIC programs into optimized
Z80 machine code while maintaining strong compatibility with the MSX
BASIC environment and ecosystem.

This document describes the **internal architecture** of the
**MSXBAS2ROM** compiler and the structure of the ROM images it
produces.

The goal is to provide a clear overview of how a BASIC source file is
transformed into a bootable MSX ROM cartridge and how the generated
program is organized in memory.

------------------------------------------------------------------------

# Compilation Flow

The compiler follows a traditional multi‑phase compilation pipeline
adapted for MSX BASIC semantics and the constraints of the Z80
architecture.

The main phases are:

1.  **Lexical Analysis**
2.  **Syntactic Analysis**
3.  **Semantic Analysis and Code Generation**
4.  **Binary Building and ROM Packaging**

Each phase progressively transforms the source program into a
lower-level representation until it becomes a valid MSX ROM image.

------------------------------------------------------------------------

## 1. Lexical Analysis

During lexical analysis, the source code is scanned and divided into
**atomic elements called lexemes**.

Examples of lexemes include:

-   Keywords (`IF`, `FOR`, `GOTO`, `PRINT`)
-   Identifiers (variable names)
-   Operators (`+`, `-`, `*`, `/`, `AND`, `OR`)
-   Literals (numbers and strings)
-   Delimiters (`(` `)` `,` `:`)

The lexical analyzer converts the text source into a **token stream**,
which simplifies further processing by removing formatting concerns such
as whitespace or comments.

Key responsibilities:

-   Token identification
-   Numeric literal parsing
-   String literal handling
-   BASIC keyword recognition
-   Error detection for invalid tokens

The result of this phase is a **sequence of tokens** used by the parser.

------------------------------------------------------------------------

## 2. Syntactic Analysis

The syntactic analysis phase interprets the token stream and validates
it against the **grammar rules of MSX BASIC**.

During this phase the compiler builds an **Abstract Syntax Tree (AST)**
representing the structure of the program.

Typical constructs represented in the AST include:

-   Expressions
-   Statements
-   Control flow structures
-   Function calls
-   Variable references

Example BASIC statement:

    IF A > 10 THEN PRINT "HELLO"

This becomes a tree describing:

-   A conditional expression (`A > 10`)
-   A conditional branch
-   A PRINT command with a string literal

The AST becomes the **central intermediate representation** used in the
rest of the compilation pipeline.

------------------------------------------------------------------------

## 3. Semantic Analysis and Code Generation

Once the AST is built, the compiler performs **semantic analysis** to
ensure the program is logically correct and to prepare for code
generation.

Major tasks in this phase include:

### Symbol Table Construction

The compiler builds a **symbol table** containing information about:

-   Variables
-   Arrays
-   Labels
-   Functions
-   Constants

This table allows the compiler to resolve identifiers and allocate
memory locations.

### Type and Context Validation

Although MSX BASIC is loosely typed, the compiler must still verify:

-   Valid function usage
-   Correct parameter counts
-   Valid variable contexts
-   Control flow correctness

### Z80 Code Generation

After semantic validation, the compiler generates **Z80 assembly
instructions**.

These instructions are emitted using an internal code builder that:

-   Translates BASIC statements to Z80 routines
-   Calls runtime support functions
-   Handles expression evaluation
-   Manages stack usage

The output of this stage is a **relocatable code representation** ready
to be assembled into the final ROM image.

------------------------------------------------------------------------

## 4. Binary Building and ROM Packaging

In the final stage the compiler produces a **complete MSX ROM image**.

This stage includes:

-   Translating generated code into binary form
-   Linking runtime modules
-   Linking resources (maps, data, assets)
-   Resolving symbol references
-   Organizing memory segments
-   Producing the final ROM file

The final result is a **ROM cartridge binary** that can run on:

-   Real MSX hardware
-   MSX emulators
-   Flash cartridges

------------------------------------------------------------------------

# Design Goals

The MSXBAS2ROM compiler was designed around several key principles.

## MSX BASIC Compatibility

The compiler aims to maintain strong compatibility with **MSX BASIC
syntax and semantics**, enabling existing programs to be ported with
minimal changes.

## Cross‑Platform Tooling

The compiler is implemented as a **command line tool** compatible with:

-   Linux
-   Windows
-   macOS

This allows integration into modern development workflows and build
pipelines.

## Expandability

The architecture supports extensibility through:

-   New compiler directives
-   Extended BASIC commands
-   Additional runtime modules
-   External resource integration

## Performance

One of the main goals of MSXBAS2ROM is to generate **fast Z80 machine
code**, significantly outperforming interpreted BASIC execution.

------------------------------------------------------------------------

# ROM Memory Scheme

Programs compiled with MSXBAS2ROM are packaged into a ROM image that
follows the **MSX cartridge memory model**.

The MSX memory space is divided into **four pages of 16 KB each**,
totaling 64 KB of addressable memory.

Different ROM formats may organize these pages differently depending on
the cartridge type.

------------------------------------------------------------------------

# Plain ROM Memory Scheme

Plain ROM cartridges are typically **48 KB** in size.

They occupy three ROM pages while the last page is RAM used during
execution.

## Overview

    +----------------------------------------------------+
    | PAGE 0 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BIOS                                       |
    |----------------------------------------------------|
    | USER RESOURCES                                     |
    |   ├─ MAP                                           |
    |   └─ DATA                                          |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 1 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BASIC                                      |
    |----------------------------------------------------|
    | COMPILER RUNTIME KERNEL                            |
    |   ├─ MSX Boot Loader                               |
    |   ├─ General Support Routines                      |
    |   ├─ Tiny Sprite Support                           |
    |   ├─ MSX Tile Forge Support                        |
    |   ├─ Arkos Tracker Support                         |
    |   └─ Floating Point Math Pack                      |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (16K)                                       |
    |----------------------------------------------------|
    | BASIC Boot Loader                                  |
    | USER CODE                                          |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 3 (16K)                                       |
    |----------------------------------------------------|
    | MSX RAM                                            |
    |   ├─ Kernel Workspace (flags)                      |
    |   ├─ User Workspace (variables)                    |
    |   ├─ Code Stack                                    |
    |   └─ MSX BIOS Workspace and routines               |
    +----------------------------------------------------+

### Description

- **Page 0**: Contains system BIOS and optional user resources such as tile maps or
game data;
- **Page 1**: Contains the runtime kernel required for executing compiled BASIC
programs;
- **Page 2**: Stores the compiled program code and boot loader responsible for
starting the application;
- **Page 3**: Represents RAM used for runtime execution including variables and stack.

------------------------------------------------------------------------

# MegaROM Memory Scheme (Konami SCC / ASCII8)

Large programs and games often require ROM sizes larger than 48 KB.

For this reason the compiler also supports **MegaROM cartridges**,
typically ranging from:

**128 KB up to 2048 KB**.

These cartridges use **bank switching** to dynamically map ROM segments
into the address space.

## Overview

    +----------------------------------------------------+
    | PAGE 0 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BIOS                                       |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 1 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BASIC                                      |
    |----------------------------------------------------|
    | Segments 0 (8K) and 1 (8K)                         |
    |                                                    |
    | COMPILER RUNTIME KERNEL                            |
    |   ├─ MSX Boot Loader                               |
    |   ├─ General Support Routines                      |
    |   ├─ Tiny Sprite Support                           |
    |   ├─ MSX Tile Forge Support                        |
    |   ├─ Arkos Tracker Support                         |
    |   └─ Floating Point Math Pack                      |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (16K)                                       |
    |----------------------------------------------------|
    | Segments 2..N                                      |
    |                                                    |
    | BASIC Boot Loader                                  |
    | USER CODE                                          |
    | Additional code banks                              |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (continued after code segments)             |
    |----------------------------------------------------|
    | USER RESOURCES                                     |
    |   ├─ MAP segments                                  |
    |   └─ DATA segments                                 |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 3 (16K)                                       |
    |----------------------------------------------------|
    | MSX RAM                                            |
    |   ├─ Kernel Workspace (flags)                      |
    |   ├─ User Workspace (variables)                    |
    |   ├─ Code Stack                                    |
    |   └─ MSX BIOS Workspace                            |
    +----------------------------------------------------+

### Bank Switching

MegaROM cartridges use mapper hardware such as:

-   **Konami SCC**
-   **ASCII8**

These allow different **8 KB segments** of the ROM to be dynamically
mapped into memory during program execution.

This enables:

-   Very large games
-   Streaming of assets
-   Large maps and resources
-   Music and sound data banks

------------------------------------------------------------------------

# Additional Resources

See [compiler process flow model](https://github.com/amaurycarvalho/msxbas2rom/blob/master/doc/Architectural%20model.pdf) for more detailed information.

------------------------------------------------------------------------

📌 See also [Resource Directives](https://github.com/amaurycarvalho/msxbas2rom/wiki/Resource-Directives), [Extended Commands](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands) and [Extended Functions](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Functions).
