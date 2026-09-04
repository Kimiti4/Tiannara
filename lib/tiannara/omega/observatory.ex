defmodule Tiannara.Omega.Observatory do
  @moduledoc """
  Observatory — runtime observability dashboard backend.
  Aggregates metrics, health, compliance, and activity data from all subsystems.
  """

  use GenServer
  require Logger

  alias Tiannara.Omega.RuntimeHealthAggregator

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec dashboard() :: map()
  def dashboard do
    GenServer.call(__MODULE__, :dashboard, 30_000)
  end

  @spec section(atom()) :: map()
  def section(name) do
    GenServer.call(__MODULE__, {:section, name})
  end

  @impl true
  def init(_opts) do
    {:ok, %{requests: 0}}
  end

  @impl true
  def handle_call(:dashboard, _from, state) do
    {:reply, build_dashboard(), %{state | requests: state.requests + 1}}
  end

  @impl true
  def handle_call({:section, name}, _from, state) do
    {:reply, Map.get(build_dashboard(), name, %{}), %{state | requests: state.requests + 1}}
  end

  defp build_dashboard do
    health = RuntimeHealthAggregator.health()
    full = RuntimeHealthAggregator.full_status()

    %{
      overview: %{status: health.status, subsystems_healthy: health.subsystems_healthy, subsystems_total: health.subsystems_total, vm_uptime_seconds: health.vm[:uptime_seconds], agency_loops: safe_call(Tiannara.Omega.AgencyLoop, & &1.loops_completed(), 0), current_phase: safe_call(Tiannara.Omega.AgencyLoop, & &1.current_phase(), :unknown), timestamp: DateTime.utc_now()},
      sentinel: %{observations_total: get_in(full, [:sentinel, :observations_total]) || 0, anomalies_detected: get_in(full, [:sentinel, :anomalies_detected]) || 0, active_priorities: get_in(full, [:sentinel, :active_priorities]) || 0, patterns_tracked: get_in(full, [:sentinel, :patterns_tracked]) || 0},
      research: %{active_hypotheses: get_in(full, [:research, :active_hypotheses]) || 0, pending_experiments: get_in(full, [:research, :pending_experiments]) || 0, validated_knowledge: get_in(full, [:research, :validated_knowledge]) || 0, evidence_scored: get_in(full, [:research, :evidence_scored]) || 0},
      interface: %{active_conversations: get_in(full, [:interface, :active_conversations]) || 0, pending_notifications: get_in(full, [:interface, :pending_notifications]) || 0, total_communications: get_in(full, [:interface, :total_communications]) || 0, active_collaborations: get_in(full, [:interface, :active_collaborations]) || 0},
      autonomy: %{active_proposals: get_in(full, [:autonomy, :active_proposals]) || 0, running_simulations: get_in(full, [:autonomy, :running_simulations]) || 0, total_deployed: get_in(full, [:autonomy, :total_improvements_deployed]) || 0, total_rollbacks: get_in(full, [:autonomy, :total_rollbacks]) || 0, constitutional_violations: get_in(full, [:autonomy, :constitutional_violations]) || 0},
      cognitive_runtime: %{cycles_completed: get_in(full, [:ecr, :cycles_completed]) || 0, active_attentions: get_in(full, [:ecr, :active_attentions]) || 0, last_reflection: get_in(full, [:ecr, :last_reflection]), uptime_seconds: get_in(full, [:ecr, :uptime_seconds]) || 0},
      compliance: safe_call(Tiannara.Omega.ConstitutionalComplianceMonitor, & &1.status(), %{compliant: :unknown}),
      vm: health.vm,
      executive_memory: safe_call(Tiannara.Executive.ExecutiveMemory, & &1.diagnostics(), %{available: false})
    }
  end

  defp safe_call(module, fun, default) do
    case Process.whereis(module) do
      nil -> default
      _pid ->
        try do
          fun.(module)
        catch
          _, _ -> default
        end
    end
  end
end
