defmodule TiannaraOS.Governance.DeterministicContext do
  @moduledoc """
  DeterministicContext - Provides reproducible timestamps and seeded randomness.
  
  This module ensures that all governance operations are deterministic by:
  1. Using a fixed base timestamp instead of DateTime.utc_now()
  2. Providing seeded random number generation
  3. Ensuring consistent ordering of collections
  
  ## Usage
  
      # Create context with specific seed
      ctx = DeterministicContext.new(seed: 42, base_time: ~U[2026-01-01 00:00:00Z])
      
      # Get deterministic timestamp (increments on each call)
      ts1 = DeterministicContext.next_timestamp(ctx)
      ts2 = DeterministicContext.next_timestamp(ctx)
      
      # Get seeded random value
      rand_val = DeterministicContext.random(ctx)
      
      # Use in campaign execution
      {:ok, result} = Laboratory.execute_campaign(:gc_001_replay, context: ctx)
  
  ## Constitutional Principle
  
  **All certification must be reproducible.** By controlling timestamps and
  randomness, we ensure that the same inputs always produce the same outputs,
  enabling cold boot reproducibility verification.
  """
  
  defstruct [
    :seed,
    :base_time,
    :timestamp_counter,
    :random_state
  ]
  
  @type t :: %__MODULE__{
    seed: integer(),
    base_time: DateTime.t(),
    timestamp_counter: integer(),
    random_state: any()
  }
  
  @doc """
  Create a new deterministic context.
  
  ## Options
  
  - `:seed` - Random seed (integer). Default: 42
  - `:base_time` - Base timestamp for all operations. Default: 2026-01-01 00:00:00Z
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    base_time = Keyword.get(opts, :base_time, ~U[2026-01-01 00:00:00Z])
    
    %__MODULE__{
      seed: seed,
      base_time: base_time,
      timestamp_counter: 0,
      random_state: :rand.seed(:exsplus, {seed, seed, seed})
    }
  end
  
  @doc """
  Generate next deterministic timestamp.
  
  Each call increments an internal counter and adds milliseconds to base_time,
  ensuring unique but reproducible timestamps.
  """
  @spec next_timestamp(t()) :: {DateTime.t(), t()}
  def next_timestamp(%__MODULE__{} = ctx) do
    new_counter = ctx.timestamp_counter + 1
    
    # Add milliseconds to base time (counter * 1ms)
    new_time = DateTime.add(ctx.base_time, new_counter, :millisecond)
    
    new_ctx = %{ctx | timestamp_counter: new_counter}
    
    {new_time, new_ctx}
  end
  
  @doc """
  Generate deterministic random integer in range [min, max].
  """
  @spec random_int(t(), integer(), integer()) :: {integer(), t()}
  def random_int(%__MODULE__{} = ctx, min, max) do
    {value, new_state} = :rand.uniform_s(max - min + 1, ctx.random_state)
    result = min + value - 1
    
    new_ctx = %{ctx | random_state: new_state}
    
    {result, new_ctx}
  end
  
  @doc """
  Generate deterministic random float in range [0.0, 1.0].
  """
  @spec random_float(t()) :: {float(), t()}
  def random_float(%__MODULE__{} = ctx) do
    {value, new_state} = :rand.uniform_s(ctx.random_state)
    new_ctx = %{ctx | random_state: new_state}
    
    {value, new_ctx}
  end
  
  @doc """
  Select random element from list deterministically.
  """
  @spec random_choice(t(), list()) :: {any(), t()}
  def random_choice(%__MODULE__{} = ctx, list) when is_list(list) and length(list) > 0 do
    index = length(list)
    {rand_idx, new_ctx} = random_int(ctx, 1, index)
    
    {Enum.at(list, rand_idx - 1), new_ctx}
  end
  
  @doc """
  Shuffle list deterministically using Fisher-Yates algorithm.
  """
  @spec shuffle(t(), list()) :: {list(), t()}
  def shuffle(%__MODULE__{} = ctx, list) do
    shuffled = do_shuffle(ctx, Enum.reverse(list), [])
    {shuffled, ctx}
  end
  
  defp do_shuffle(_ctx, [], acc), do: acc
  
  defp do_shuffle(ctx, [h | t], acc) do
    n = length([h | t])
    {j, new_ctx} = random_int(ctx, 0, n - 1)
    
    # Swap element at position j with head
    swapped = swap_elements([h | t], 0, j)
    [swapped_head | rest] = swapped
    
    do_shuffle(new_ctx, rest, [swapped_head | acc])
  end
  
  defp swap_elements(list, i, j) do
    list
    |> List.replace_at(i, Enum.at(list, j))
    |> List.replace_at(j, Enum.at(list, i))
  end
  
  @doc """
  Sort list deterministically (always same order for same input).
  """
  @spec sort_deterministic(list()) :: list()
  def sort_deterministic(list) when is_list(list) do
    Enum.sort(list, &term_comparator/2)
  end
  
  defp term_comparator(a, b) do
    :erlang.term_to_binary(a) <= :erlang.term_to_binary(b)
  end
  
  @doc """
  Generate deterministic UUID-like identifier.
  
  Uses seed and counter to create reproducible IDs.
  """
  @spec generate_id(t(), String.t()) :: {String.t(), t()}
  def generate_id(%__MODULE__{} = ctx, prefix) do
    {rand_part, new_ctx} = random_int(ctx, 100000, 999999)
    id = "#{prefix}-#{rand_part}"
    
    {id, new_ctx}
  end
  
  @doc """
  Reset context to initial state (for replay scenarios).
  """
  @spec reset(t()) :: t()
  def reset(%__MODULE__{seed: seed, base_time: base_time} = _ctx) do
    new(seed: seed, base_time: base_time)
  end
  
  @doc """
  Get current context metadata for debugging/logging.
  """
  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{} = ctx) do
    %{
      seed: ctx.seed,
      base_time: DateTime.to_iso8601(ctx.base_time),
      timestamp_counter: ctx.timestamp_counter,
      has_random_state: ctx.random_state != nil
    }
  end
end
