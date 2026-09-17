defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ScientificCapital do
  @moduledoc """
  Phase 16.1 Module 9 — Scientific Capital Runtime (Pure Implementation)

  Tracks capital metrics deterministically:
  - Scientific Capital, Knowledge Capital, Research Debt, Discovery Fitness

  Every discovery changes these metrics in a deterministic way.
  """

  @capital_table :scientific_capital

  def init_table do
    if :ets.info(@capital_table) == :undefined do
      :ets.new(@capital_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Initialize capital ledger with seed values"
  @spec init_capital(map()) :: :ok
  def init_capital(seed_values) do
    init_table()
    ledger = Map.merge(init_ledger(), canonicalize_map(seed_values))
    :ets.insert(@capital_table, {"state", ledger})
    :ok
  end

  @doc "Apply capital event deterministically"
  @spec apply_event(map()) :: map()
  def apply_event(event) do
    init_table()
    current_ledger = get_state()
    new_ledger = apply_capital_event(current_ledger, event)
    :ets.insert(@capital_table, {"state", new_ledger})
    new_ledger
  end

  @doc "Get current capital state"
  @spec get_state() :: map()
  def get_state do
    init_table()
    case :ets.lookup(@capital_table, "state") do
      [{"state", ledger}] -> ledger
      [] -> init_ledger()
    end
  end

  @doc "Replay capital state from events"
  @spec replay([map()]) :: map()
  def replay(events) do
    Enum.reduce(events, init_ledger(), fn event, ledger -> apply_capital_event(ledger, event) end)
  end

  # --- internal helpers ---

  defp init_ledger do
    %{
      "scientific_capital" => 0,
      "knowledge_capital" => 0,
      "research_debt" => 0,
      "discovery_fitness" => 0.0
    }
  end

  defp apply_capital_event(ledger, %{"type" => "discovery", "value" => value}) do
    Map.put(ledger, "scientific_capital", Map.get(ledger, "scientific_capital", 0) + value)
  end

  defp apply_capital_event(ledger, %{"type" => "knowledge", "value" => value}) do
    Map.put(ledger, "knowledge_capital", Map.get(ledger, "knowledge_capital", 0) + value)
  end

  defp apply_capital_event(ledger, %{"type" => "debt", "value" => value}) do
    Map.put(ledger, "research_debt", Map.get(ledger, "research_debt", 0) + value)
  end

  defp apply_capital_event(ledger, %{"type" => "fitness", "value" => value}) do
    Map.put(ledger, "discovery_fitness", Map.get(ledger, "discovery_fitness", 0.0) + value)
  end

  defp apply_capital_event(ledger, _event), do: ledger

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
