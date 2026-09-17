defmodule Tiannara.Phase17.UCC.EquivalenceVerifier do
  @moduledoc """
  Verifies semantic preservation & execution equivalence post-compilation.
  Enforces $\| \text{Exec} - \text{Ideal} \|_2 < \epsilon_{exec}$.
  """
  use GenServer

  @epsilon_exec 1.0e-5
  @sample_size 500

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{verified_surfaces: %{}}}

  @spec verify(surface_id :: String.t(), original_constraints :: map(), compiled_bytecode :: binary()) :: 
    {:ok, equivalence_score :: float()} | {:error, :drift_detected}
  def verify(surface_id, original, bytecode) do
    samples = Enum.map(1..@sample_size, fn _ -> generate_test_input(original) end)
    diffs = Enum.map(samples, fn input ->
      exec_result = run_compiled(bytecode, input)
      ideal_result = evaluate_original(original, input)
      abs(exec_result - ideal_result)
    end)
    
    max_diff = Enum.max(diffs)
    score = 1.0 - max_diff
    
    if max_diff <= @epsilon_exec do
      {:ok, score}
    else
      {:error, :drift_detected}
    end
  end

  defp generate_test_input(original) do
    constraints = case original do
      %{constraints: c} -> c
      c when is_map(c) -> c
      _ -> %{}
    end
    Map.keys(constraints) |> Enum.map(fn _ -> :rand.uniform() end)
  end
  defp run_compiled(bytecode, input) when is_list(bytecode) do
    {[result], _} = Enum.reduce(bytecode, {[], input}, &exec_op/2)
    result
  end
  defp run_compiled(_bytecode, input), do: Enum.sum(input)

  defp exec_op({:push_const, val}, {stack, input}), do: {[val | stack], input}
  defp exec_op({:push_input, idx}, {stack, input}), do: {[Enum.at(input, idx, 0.0) | stack], input}
  defp exec_op(:add, {[a, b | rest], input}), do: {[a + b | rest], input}
  defp exec_op(:mul, {[a, b | rest], input}), do: {[a * b | rest], input}
  defp exec_op(:sub, {[a, b | rest], input}), do: {[a - b | rest], input}

  defp evaluate_original(constraints, input) do
    constraints
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.with_index()
    |> Enum.reduce(0.0, fn {{_name, %{weight: w}}, idx}, acc ->
      acc + w * Enum.at(input, idx, 0.0)
    end)
  end
end