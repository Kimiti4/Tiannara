defmodule TiannaraOS.Governance.GovernanceCostLedger do
  @moduledoc """
  GovernanceCostLedger - Immutable ledger tracking all governance resource consumption.

  Every governance action consumes resources (compute, human review time, deployment
  downtime, etc.). This ledger provides complete transparency into governance costs
  and enables cost-benefit analysis of institutional decisions.

  ## Cost Categories

  - **Simulation Costs**: CPU hours, memory usage for proposal simulations
  - **Review Costs**: Human reviewer time, automated analysis compute
  - **Deployment Costs**: Migration downtime, rollback preparation
  - **Audit Costs**: Compliance verification, provenance tracking
  - **Replay Costs**: State reconstruction, verification compute
  - **Administrative Costs**: Appointment processing, institution management

  ## Cost Weights

  - CPU hour: $0.10
  - Memory GB-hour: $0.05
  - Reviewer hour: $1.00 (normalized unit)
  - Deployment downtime ms: $0.001
  - Rollback operation: $5.00 base cost

  ## API

      @spec record_cost(atom(), map()) :: {:ok, cost_entry()} | {:error, term()}
      @spec get_total_costs() :: map()
      @spec get_costs_by_category(atom()) :: [cost_entry()]
      @spec compute_net_utility(float(), float()) :: float()
      @spec cost_effective?(scientific_benefits :: float(), total_costs :: float()) :: boolean()
  """

  use GenServer

  defstruct [
    :entry_id,
    :cost_type,
    :category,
    :amount,
    :unit,
    :cost_usd,
    :associated_entity_id,
    :description,
    :timestamp,
    :metadata
  ]

  @type t :: %__MODULE__{
          entry_id: String.t(),
          cost_type: atom(),
          category: atom(),
          amount: float(),
          unit: String.t(),
          cost_usd: float(),
          associated_entity_id: String.t() | nil,
          description: String.t(),
          timestamp: DateTime.t(),
          metadata: map()
        }

  # Cost weights for normalization to USD
  @cpu_hour_cost 0.1       # $0.10 per CPU hour
  @memory_gb_hour_cost 0.05 # $0.05 per GB-hour
  @reviewer_hour_cost 1.0   # $1.00 per reviewer hour (normalized)
  @downtime_ms_cost 0.001   # $0.001 per millisecond downtime
  @rollback_base_cost 5.0   # Base cost for rollback operation
  @audit_base_cost 2.0      # Base cost for audit operation
  @administrative_base_cost 0.5 # Base cost for administrative operations

  @doc """
  Start the GovernanceCostLedger GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Record a governance cost event.

  ## Examples

      # Record simulation cost
      GovernanceCostLedger.record_cost(:simulation_cpu, %{
        cpu_hours: 2.5,
        proposal_id: "prop-123"
      })

      # Record review cost
      GovernanceCostLedger.record_cost(:review_time, %{
        reviewer_hours: 4.0,
        proposal_id: "prop-123",
        reviewer_count: 3
      })

      # Record deployment cost
      GovernanceCostLedger.record_cost(:deployment_downtime, %{
        downtime_ms: 5000,
        proposal_id: "prop-123"
      })
  """
  @spec record_cost(atom(), map()) :: {:ok, t()} | {:error, term()}
  def record_cost(cost_type, metadata) when is_atom(cost_type) and is_map(metadata) do
    GenServer.call(__MODULE__, {:record_cost, cost_type, metadata})
  end

  @doc """
  Get all cost entries.
  """
  @spec get_all_costs() :: [t()]
  def get_all_costs() do
    GenServer.call(__MODULE__, :get_all_costs)
  end

  @doc """
  Get raw cost logs with optional limit.
  
  Alias for get_all_costs/0 with pagination support.
  """
  @spec get_raw_cost_logs(keyword()) :: [t()]
  def get_raw_cost_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    all_costs = get_all_costs()
    
    if limit do
      Enum.take(all_costs, limit)
    else
      all_costs
    end
  end

  @doc """
  Get costs filtered by category.
  """
  @spec get_costs_by_category(atom()) :: [t()]
  def get_costs_by_category(category) do
    GenServer.call(__MODULE__, {:get_costs_by_category, category})
  end

  @doc """
  Get costs associated with a specific entity (proposal, institution, etc.).
  """
  @spec get_costs_by_entity(String.t()) :: [t()]
  def get_costs_by_entity(entity_id) do
    GenServer.call(__MODULE__, {:get_costs_by_entity, entity_id})
  end

  @doc """
  Calculate total costs across all categories.
  """
  @spec get_total_costs() :: map()
  def get_total_costs() do
    GenServer.call(__MODULE__, :get_total_costs)
  end

  @doc """
  Get cost summary (alias for get_total_costs/0).
  """
  @spec get_cost_summary() :: map()
  def get_cost_summary() do
    get_total_costs()
  end

  @doc """
  Calculate total costs for a specific entity.
  """
  @spec get_entity_total_cost(String.t()) :: float()
  def get_entity_total_cost(entity_id) do
    GenServer.call(__MODULE__, {:get_entity_total_cost, entity_id})
  end

  @doc """
  Compute net utility: benefits minus costs.

  Returns positive value if benefits exceed costs.
  """
  @spec compute_net_utility(float(), float()) :: float()
  def compute_net_utility(scientific_benefits, total_costs) do
    Float.round(scientific_benefits - total_costs, 4)
  end

  @doc """
  Determine if an action is cost-effective.

  Returns true if scientific benefits exceed governance costs.
  """
  @spec cost_effective?(float(), float()) :: boolean()
  def cost_effective?(scientific_benefits, total_costs) do
    compute_net_utility(scientific_benefits, total_costs) > 0
  end

  @doc """
  Get cost summary report.
  """
  @spec get_cost_report() :: map()
  def get_cost_report() do
    GenServer.call(__MODULE__, :get_cost_report)
  end

  @doc """
  Export cost ledger for external audit.
  """
  @spec export_for_audit() :: [map()]
  def export_for_audit() do
    GenServer.call(__MODULE__, :export_for_audit)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      entries: [],
      entry_counter: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:record_cost, cost_type, metadata}, _from, state) do
    now = DateTime.utc_now()
    counter = state.entry_counter + 1

    # Calculate cost in USD based on type
    {amount, unit, cost_usd} = calculate_cost(cost_type, metadata)

    entry = %__MODULE__{
      entry_id: generate_entry_id(counter),
      cost_type: cost_type,
      category: categorize_cost(cost_type),
      amount: amount,
      unit: unit,
      cost_usd: Float.round(cost_usd, 4),
      associated_entity_id: Map.get(metadata, :proposal_id) || Map.get(metadata, :entity_id),
      description: describe_cost(cost_type, metadata),
      timestamp: now,
      metadata: metadata
    }

    new_state = %{
      state
      | entries: state.entries ++ [entry],
        entry_counter: counter
    }

    {:reply, {:ok, entry}, new_state}
  end

  @impl true
  def handle_call(:get_all_costs, _from, state) do
    {:reply, state.entries, state}
  end

  @impl true
  def handle_call({:get_costs_by_category, category}, _from, state) do
    filtered = Enum.filter(state.entries, fn entry -> entry.category == category end)
    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:get_costs_by_entity, entity_id}, _from, state) do
    filtered = Enum.filter(state.entries, fn entry ->
      entry.associated_entity_id == entity_id
    end)
    {:reply, filtered, state}
  end

  @impl true
  def handle_call(:get_total_costs, _from, state) do
    totals = calculate_totals(state.entries)
    {:reply, totals, state}
  end

  @impl true
  def handle_call({:get_entity_total_cost, entity_id}, _from, state) do
    entity_costs =
      state.entries
      |> Enum.filter(fn entry -> entry.associated_entity_id == entity_id end)
      |> Enum.map(fn entry -> entry.cost_usd end)

    total = Enum.sum(entity_costs)
    {:reply, Float.round(total, 4), state}
  end

  @impl true
  def handle_call(:get_cost_report, _from, state) do
    totals = calculate_totals(state.entries)

    report = %{
      timestamp: DateTime.utc_now(),
      total_entries: length(state.entries),
      total_cost_usd: totals.total_cost_usd,
      costs_by_category: totals.by_category,
      costs_by_type: totals.by_type,
      average_cost_per_entry:
        if length(state.entries) > 0 do
          Float.round(totals.total_cost_usd / length(state.entries), 4)
        else
          0.0
        end
    }

    {:reply, report, state}
  end

  @impl true
  def handle_call(:export_for_audit, _from, state) do
    exported =
      Enum.map(state.entries, fn entry ->
        %{
          entry_id: entry.entry_id,
          cost_type: entry.cost_type,
          category: entry.category,
          amount: entry.amount,
          unit: entry.unit,
          cost_usd: entry.cost_usd,
          associated_entity_id: entry.associated_entity_id,
          description: entry.description,
          timestamp: DateTime.to_iso8601(entry.timestamp),
          metadata: entry.metadata
        }
      end)

    {:reply, exported, state}
  end

  # Private helpers

  defp generate_entry_id(counter) do
    "gov-cost-#{String.pad_leading(Integer.to_string(counter), 6, "0")}-#{System.system_time(:millisecond)}"
  end

  defp calculate_cost(:simulation_cpu, %{cpu_hours: hours}), do: {hours, "cpu_hours", hours * @cpu_hour_cost}
  defp calculate_cost(:simulation_memory, %{memory_gb_hours: gb_hours}), do: {gb_hours, "gb_hours", gb_hours * @memory_gb_hour_cost}
  defp calculate_cost(:review_time, %{reviewer_hours: hours}), do: {hours, "reviewer_hours", hours * @reviewer_hour_cost}
  defp calculate_cost(:deployment_downtime, %{downtime_ms: ms}), do: {ms / 1.0, "milliseconds", ms * @downtime_ms_cost}
  defp calculate_cost(:rollback, _metadata), do: {1.0, "operation", @rollback_base_cost}
  defp calculate_cost(:audit, _metadata), do: {1.0, "operation", @audit_base_cost}
  defp calculate_cost(:administrative, _metadata), do: {1.0, "operation", @administrative_base_cost}

  # Fallback for missing required fields
  defp calculate_cost(:simulation_cpu, _metadata), do: {0.0, "cpu_hours", 0.0}
  defp calculate_cost(:simulation_memory, _metadata), do: {0.0, "gb_hours", 0.0}
  defp calculate_cost(:review_time, _metadata), do: {0.0, "reviewer_hours", 0.0}
  defp calculate_cost(:deployment_downtime, _metadata), do: {0.0, "milliseconds", 0.0}

  defp categorize_cost(cost_type) do
    case cost_type do
      :simulation_cpu -> :simulation
      :simulation_memory -> :simulation
      :review_time -> :review
      :deployment_downtime -> :deployment
      :rollback -> :deployment
      :audit -> :audit
      :administrative -> :administrative
      _ -> :other
    end
  end

  defp describe_cost(:simulation_cpu, %{proposal_id: prop_id}),
    do: "Simulation CPU cost for proposal #{prop_id}"
  defp describe_cost(:simulation_memory, %{proposal_id: prop_id}),
    do: "Simulation memory cost for proposal #{prop_id}"
  defp describe_cost(:review_time, %{proposal_id: prop_id}),
    do: "Review time cost for proposal #{prop_id}"
  defp describe_cost(:deployment_downtime, %{proposal_id: prop_id}),
    do: "Deployment downtime cost for proposal #{prop_id}"
  defp describe_cost(:rollback, %{proposal_id: prop_id}),
    do: "Rollback cost for proposal #{prop_id}"
  defp describe_cost(cost_type, _metadata),
    do: "Governance cost: #{inspect(cost_type)}"

  defp calculate_totals(entries) do
    total_cost_usd = Enum.sum(Enum.map(entries, fn e -> e.cost_usd end))

    by_category =
      entries
      |> Enum.group_by(fn e -> e.category end)
      |> Enum.map(fn {cat, entries_list} ->
        {cat, Float.round(Enum.sum(Enum.map(entries_list, fn e -> e.cost_usd end)), 4)}
      end)
      |> Enum.into(%{})

    by_type =
      entries
      |> Enum.group_by(fn e -> e.cost_type end)
      |> Enum.map(fn {type, entries_list} ->
        {type, Float.round(Enum.sum(Enum.map(entries_list, fn e -> e.cost_usd end)), 4)}
      end)
      |> Enum.into(%{})

    %{      total_cost_usd: Float.round(total_cost_usd + 0.0, 4),
      by_category: by_category,
      by_type: by_type
    }
  end
end
