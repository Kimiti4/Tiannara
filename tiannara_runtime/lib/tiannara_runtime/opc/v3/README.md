# OPC v3 - Ontological Physics Compiler Version 3

## Overview

OPC v3 represents a complete architectural overhaul of the Observer Physics Compiler, transforming it from a dynamic symbolic runtime system into a strict intermediate representation compiler for cognitive physics.

## Core Design Principle

**"No raw syntax survives parsing. Everything becomes typed IR before execution."**

This principle ensures that all raw atoms and mixed AST shapes are eliminated before reaching the execution phase, preventing the crashes that plagued earlier versions.

## Pipeline Architecture

```
SOURCE STRING
     ↓
Tokenizer
     ↓
Parser (syntax-only)
     ↓
🧱 OIR Builder (NEW CORE)
     ↓
Validator (STRICT CONTRACT)
     ↓
Normalizer (canonical AST)
     ↓
Compiler Passes
     ↓
Execution IR (EIR)
     ↓
Runtime / MSCL / OLEF
```

## Key Components

### 1. OIR (Ontological Intermediate Representation)

The core data model that ensures type safety:

```elixir
defstruct [
  :type,
  :op,
  :value,
  :children,
  :meta
]

@type t :: %__MODULE__{
  type: :number | :string | :boolean | :binary | :unary | :function | :tensor | :conditional | :identifier,
  op: atom() | nil,
  value: any(),
  children: list(t()),
  meta: map()
}
```

### 2. Parser (Syntax Only)

The parser produces only raw syntax trees without evaluation logic:

- `{:raw_binary, :+, left, right}`
- `{:raw_function, :sqrt, args}`
- `{:number, value}`

### 3. OIR Builder

Converts raw syntax trees to strict OIR, eliminating `:+` leakage forever:

```elixir
def build({:raw_binary, op, l, r}) do
  %OIR{
    type: :binary,
    op: op,
    children: [build(l), build(r)],
    meta: %{},
    value: nil
  }
end
```

### 4. Strict Validator

Prevents all runtime crashes by validating IR structure:

```elixir
def validate(%OIR{type: :binary, op: op, children: [left, right]}) do
  with :ok <- validate(left),
       :ok <- validate(right) do
    :ok
  end
end
```

### 5. Normalizer

Removes operator leakage completely:

```elixir
defp normalize_op(:+), do: :add
defp normalize_op(:-), do: :sub
defp normalize_op(:*), do: :mul
defp normalize_op(:/), do: :div
```

## Fixed Issues

- ✅ AST.depth crash → Impossible (no raw atoms in traversal)
- ✅ `:+` leakage → Eliminated at IR boundary
- ✅ Mixed AST formats → Replaced with single OIR schema
- ✅ Parser inconsistency → Split syntax vs semantics
- ✅ v2 instability → Removed structural ambiguity entirely

## Compiler Passes

1. **Constant Folding** - Evaluates compile-time constants
2. **Depth Analysis** - Ensures safety bounds
3. **Safety Injector** - Adds bounds checking
4. **Tensor Lift** - Optimizes tensor operations

## Benefits

- **Crash Prevention**: Raw atoms can no longer reach execution
- **Type Safety**: Strict IR prevents mixed shape errors
- **Modularity**: Clear separation of concerns
- **Extensibility**: Easy to add new compiler passes
- **Performance**: Optimized execution path

## Future Integration

OPC v3 enables safe support for:
- MSCL integration (safe)
- OLEF diffusion (safe)
- GPU compilation path
- Observer physics compilation (5F.6 ready)
- Deterministic execution graphs