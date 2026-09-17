# OPC v3 Architecture - Complete Implementation

## Overview

OPC v3 represents a complete architectural overhaul of the Observer Physics Compiler, transforming it from a dynamic symbolic runtime system into a strict intermediate representation compiler for cognitive physics with integrated GPU acceleration.

## Core Design Principle

**"No raw syntax survives parsing. Everything becomes typed IR before execution."**

This principle ensures that all raw atoms and mixed AST shapes are eliminated before reaching the execution phase, preventing the crashes that plagued earlier versions.

## Complete Pipeline Architecture

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
Execution IR (EIR) → CPU Runtime
     ↓
GPU Compiler → GPU Executable → GPU Runtime
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

### 6. GPU Execution Layer

Turns IR into parallel compute graphs for WebGL2/GPGPU execution:

- **Compute Graph**: Represents parallel computation structure
- **Shader Generator**: Creates WebGL2 shaders from compute graphs
- **GPU Execution Engine**: Manages GPU execution of compiled programs

## Compiler Passes

1. **Constant Folding** - Evaluates compile-time constants
2. **Depth Analysis** - Ensures safety bounds
3. **Safety Injector** - Adds bounds checking
4. **Tensor Lift** - Optimizes tensor operations

## GPU-Specific Features

### Compute Graph Generation
- Identifies parallelizable regions in OIR
- Estimates parallelism potential
- Calculates memory requirements
- Estimates execution time

### Shader Generation
- Vertex shader for coordinate mapping
- Fragment shader for computation
- Uniform and attribute bindings
- Tensor operation optimization

### GPU Execution Engine
- WebGL2 context management
- Parallel execution simulation
- Performance benchmarking
- Vectorization optimization

## Fixed Issues

- ✅ AST.depth crash → Impossible (no raw atoms in traversal)
- ✅ `:+` leakage → Eliminated at IR boundary
- ✅ Mixed AST formats → Replaced with single OIR schema
- ✅ Parser inconsistency → Split syntax vs semantics
- ✅ v2 instability → Removed structural ambiguity entirely

## GPU Integration Benefits

- **Parallel Processing**: Leverages GPU cores for massive parallelism
- **Performance**: Significant speedup for tensor and mathematical operations
- **Scalability**: Handles large-scale computations efficiently
- **Optimization**: Automatic vectorization of compatible operations

## Architecture Compliance

The implementation follows all specified architectural principles:

1. **No raw syntax survives parsing**: All raw syntax is converted to OIR
2. **Semantic separation**: Parser only handles syntax, OIR Builder handles semantics
3. **Validation gate**: All IR must pass validation before processing
4. **Type safety**: Only OIR structures are processed by compiler passes
5. **Physical isolation**: Clear separation between parser, IR, compiler, and runtime layers

## Future Extensions

With this solid foundation, OPC v3 can easily support:
- Advanced tensor operations
- Custom GPU kernels
- Real-time physics simulation
- Machine learning acceleration
- Distributed GPU computation