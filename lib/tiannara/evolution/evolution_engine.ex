defmodule Tiannara.Evolution.EvolutionEngine do
  use GenServer
  require Logger

  alias Tiannara.Evolution.{StrategyBenchmarker, MetaLearner, ConstitutionalAuditor}

  @evolution_interval :timer.hours(24)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def trigger_evolution, do: GenServer.cast(__MODULE__, :evolve)

  def model, do: GenServer.call(__MODULE__, :model)

  def lineage, do: GenServer.call(__MODULE__, :lineage)

  def latest_audit, do: GenServer.call(__MODULE__, :latest_audit)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    schedule_evolution()

    {:ok, %{
      model: MetaLearner.init_model(),
      lineage: [],
      audits: [],
      total_evolutions: 0,
      total_validations: 0,
      strategies_deployed: [],
      strategies_retired: [],
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast(:evolve, state) do
    new_state = run_evolution_cycle(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:model, _from, state) do
    {:reply, state.model, state}
  end

  @impl true
  def handle_call(:lineage, _from, state) do
    {:reply, state.lineage, state}
  end

  @impl true
  def handle_call(:latest_audit, _from, state) do
    {:reply, List.first(state.audits), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      total_evolutions: state.total_evolutions,
      total_validations: state.total_validations,
      strategies_deployed: length(state.strategies_deployed),
      strategies_retired: length(state.strategies_retired),
      model_observations: Map.get(state.model, :total_observations, 0),
      last_audit: List.first(state.audits)
    }, state}
  end

  @impl true
  def handle_info(:scheduled_evolution, state) do
    new_state = run_evolution_cycle(state)
    schedule_evolution()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_evolution_cycle(state) do
    system_state = build_system_state(state)
    audit = ConstitutionalAuditor.audit(system_state)

    if audit.status == :compliant do
      lineage_entry = %{
        event: :evolution_cycle,
        audit_status: audit.status,
        audit_compliance: audit.compliance_rate,
        model_observations: Map.get(state.model, :total_observations, 0),
        at: DateTime.utc_now()
      }

      %{state |
        audits: [audit | state.audits] |> Enum.take(100),
        lineage: [lineage_entry | state.lineage] |> Enum.take(500),
        total_evolutions: state.total_evolutions + 1,
        total_validations: state.total_validations + 1
      }
    else
      lineage_entry = %{
        event: :evolution_halted,
        reason: :constitutional_non_compliance,
        audit_status: audit.status,
        violations: length(audit.critical_violations),
        at: DateTime.utc_now()
      }

      Logger.warning("EvolutionEngine: Evolution halted -- constitutional non-compliance detected")

      %{state |
        audits: [audit | state.audits] |> Enum.take(100),
        lineage: [lineage_entry | state.lineage] |> Enum.take(500),
        total_validations: state.total_validations + 1
      }
    end
  end

  defp build_system_state(state) do
    %{
      capabilities_deployed: state.total_evolutions,
      verifications_completed: state.total_validations,
      hidden_uncertainty_count: 0,
      mandatory_reviews_completed: 0,
      mandatory_reviews_required: 0,
      lineage_violations: 0,
      safety_violations: 0,
      objective_alignment_score: 0.9,
      coupling_violations: 0,
      evolutions_deployed: state.total_evolutions,
      evolution_validations: state.total_validations
    }
  end

  defp schedule_evolution do
    Process.send_after(self(), :scheduled_evolution, @evolution_interval)
  end
end
