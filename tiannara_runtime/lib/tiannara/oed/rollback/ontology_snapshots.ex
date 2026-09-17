defmodule Tiannara.OED.Rollback.OntologySnapshots do
  @moduledoc """
  🔄 Ontological Rollback Snapshots.

  Secure in-memory storage of verified baseline ontology configurations
  to allow emergency restorations.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Saves a verified rule snapshot in the registry.
  """
  @spec save_snapshot(rule_type :: atom(), rule :: map()) :: :ok
  def save_snapshot(rule_type, rule) do
    GenServer.call(__MODULE__, {:save, rule_type, rule})
  end

  @doc """
  Retrieves the latest verified snapshot for the rule type, falling back to a default.
  """
  @spec get_latest_snapshot(rule_type :: atom()) :: {:ok, map()} | {:error, String.t()}
  def get_latest_snapshot(rule_type) do
    GenServer.call(__MODULE__, {:fetch, rule_type})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:save, rule_type, rule}, _from, state) do
    new_state = Map.put(state, rule_type, rule)
    {:reply, :ok, new_state}
  end

  def handle_call({:fetch, rule_type}, _from, state) do
    case Map.fetch(state, rule_type) do
      {:ok, rule} ->
        {:reply, {:ok, rule}, state}

      :error ->
        # Generate default fallback snapshot
        fallback = generate_fallback(rule_type)
        {:reply, {:ok, fallback}, Map.put(state, rule_type, fallback)}
    end
  end

  # ==================== Helpers ====================

  defp generate_fallback(:compression_policy) do
    %{
      type: :compression_policy,
      body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
      invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
    }
  end

  defp generate_fallback(:diffusion_policy) do
    %{
      type: :diffusion_policy,
      body: {:diffuse, :pressure_field, 0.05, {:cap, 1.0}},
      invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
    }
  end

  defp generate_fallback(rule_type) do
    %{
      type: rule_type,
      body: {:apply, :default, []},
      invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
    }
  end
end
