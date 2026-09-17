defmodule Tiannara.Native.A10 do
  @moduledoc """
  Elixir NIF wrapper to bridge to the a10_nif Rust crate.
  Provides pure-Elixir fallback if the NIF is unavailable.
  """

  if Mix.env() == :prod and Code.ensure_loaded?(Rustler) do
    use Rustler, otp_app: :tiannara_runtime, crate: "a10_nif"
  end

  # Zero-Copy Shared Memory NIFs (with Elixir fallback)
  def allocate_state(total_size, shard_size) do
    ref = make_ref()
    table = :a10_fallback_store
    :ets.new(table, [:set, :named_table, :public, read_concurrency: true])
    :ets.insert(table, {ref, %{total_size: total_size, shard_size: shard_size, shards: %{}}})
    ref
  end

  def update_shard(resource, shard_idx, data) do
    table = :a10_fallback_store
    case :ets.lookup(table, resource) do
      [{^resource, state}] ->
        :ets.insert(table, {resource, %{state | shards: Map.put(state.shards, shard_idx, data)}})
        :ok
      [] ->
        :ok = :erlang.nif_error(:nif_not_loaded)
    end
  end

  def read_shard(resource, shard_idx) do
    table = :a10_fallback_store
    case :ets.lookup(table, resource) do
      [{^resource, state}] -> Map.get(state.shards, shard_idx, [])
      [] -> :erlang.nif_error(:nif_not_loaded)
    end
  end

  def compute_drift_shared(resource, _window_size) do
    table = :a10_fallback_store
    case :ets.lookup(table, resource) do
      [{^resource, state}] ->
        data = state.shards |> Map.values() |> List.flatten()
        if data == [], do: [], else: [Enum.sum(data) / length(data)]
      [] -> :erlang.nif_error(:nif_not_loaded)
    end
  end

  def lyapunov_shared(resource, gain_matrix) do
    table = :a10_fallback_store
    case :ets.lookup(table, resource) do
      [{^resource, state}] ->
        data = state.shards |> Map.values() |> List.flatten()
        gain_len = length(gain_matrix)
        data
        |> Enum.with_index()
        |> Enum.map(fn {d, i} -> d * d * Enum.at(gain_matrix, rem(i, gain_len), 1.0) end)
        |> Enum.sum()
      [] -> :erlang.nif_error(:nif_not_loaded)
    end
  end

  # GPU Native Scheduler Bridge
  def submit_diffusion_job(_binary_tensor, _coefficient, _ref_id, _caller_pid), do: :erlang.nif_error(:nif_not_loaded)

  # Legacy fallback NIFs
  def compute_drift(tensor_data, window_size) do
    if length(tensor_data) < window_size, do: [], else: [Enum.sum(Enum.take(tensor_data, window_size)) / window_size]
  end

  def lyapunov_v(state_vector, gain_matrix) do
    gain_len = length(gain_matrix)
    state_vector
    |> Enum.with_index()
    |> Enum.map(fn {s, i} -> s * s * Enum.at(gain_matrix, rem(i, gain_len), 1.0) end)
    |> Enum.sum()
  end
end
