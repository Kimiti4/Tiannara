defmodule Tiannara.Phase19.TCL.LatticeState do
  @moduledoc """
  Distributed rule version tracking & divergence computation.
  Maintains lattice view of cross-instance rule states.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    {:ok, %{
      lattice: %{}, # %{instance_id => %{version: v, rules_hash: h, timestamp: t}}
      divergence_cache: %{}
    }}
  end

  @spec update_instance(instance_id :: String.t(), version :: non_neg_integer(), rules_hash :: String.t()) :: :ok
  def update_instance(id, version, hash), do: GenServer.cast(__MODULE__, {:update, id, version, hash})

  @spec compute_divergence(instance_a :: String.t(), instance_b :: String.t()) :: float()
  def compute_divergence(a, b), do: GenServer.call(__MODULE__, {:divergence, a, b})

  @impl true
  def handle_cast({:update, id, version, hash}, state) do
    new_lattice = Map.put(state.lattice, id, %{version: version, rules_hash: hash, timestamp: :erlang.unique_integer([:positive])})
    {:noreply, %{state | lattice: new_lattice}}
  end

  @impl true
  def handle_call({:divergence, a, b}, _from, state) do
    ha = get_hash(state.lattice, a)
    hb = get_hash(state.lattice, b)
    div = if ha == hb, do: 0.0, else: levenshtein_distance(ha, hb) / 64.0 # Normalized to 0-1
    {:reply, div, %{state | divergence_cache: Map.put(state.divergence_cache, {a, b}, div)}}
  end

  defp get_hash(lattice, id), do: Map.get(lattice, id, %{rules_hash: ""}).rules_hash
  defp levenshtein_distance(a, b) do
    a_list = String.to_charlist(a)
    b_list = String.to_charlist(b)
    m = length(a_list)
    n = length(b_list)
    cond do
      m == 0 -> n
      n == 0 -> m
      true ->
        v0 = Enum.to_list(0..n)
        v1 = List.duplicate(0, n + 1)
        {final, _} = Enum.reduce(a_list, {v0, v1}, fn ca, {v0, v1} ->
          v1 = List.replace_at(v1, 0, Enum.at(v0, 0) + 1)
          {_, v1} = Enum.reduce(Enum.zip(b_list, Enum.to_list(1..n)), {v0, v1}, fn {cb, j}, {v0, v1} ->
            cost = if ca == cb, do: 0, else: 1
            val = min(Enum.at(v1, j - 1) + 1, min(Enum.at(v0, j) + 1, Enum.at(v0, j - 1) + cost))
            {v0, List.replace_at(v1, j, val)}
          end)
          {v1, v0}
        end)
        Enum.at(final, n)
    end
  end
end