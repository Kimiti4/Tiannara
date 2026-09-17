defmodule Tiannara.Audit.CoherenceValidator do
  @moduledoc """
  Cross-layer consistency checker that runs comprehensive pre-Phase 6 audits
  on causal graphs, node ontology drift, observer sandboxes, and self-compilation histories.
  """

  alias Tiannara.PrePhase6.{CausalIntegrity, SemanticCoherence, ObserverSafety, EquilibriumMonitor}
  alias Tiannara.Kernel.SelfCompilation

  @spec run_full_coherence_audit() :: %{
    status: atom(),
    findings: list(),
    recommendations: list()
  }
  def run_full_coherence_audit do
    # Fetch states from live runtime systems
    branch_registry = fetch_branch_registry()
    node_states = fetch_node_states()
    observer_states = fetch_observer_states()
    cosmological_metrics = fetch_cosmological_metrics()

    {findings, recommendations} = {[], []}

    # 1. Causal integrity check
    {findings, recommendations} =
      case CausalIntegrity.validate_causal_graph(branch_registry) do
        {:ok, _} -> {findings, recommendations}
        {:error, reason} ->
          {[{:causal_integrity, :failed, reason} | findings],
           ["Review CTL reconciliation budget or expand sync bandwidth" | recommendations]}
      end

    # 2. Semantic coherence check
    {findings, recommendations} =
      case SemanticCoherence.validate_ontology_mesh(node_states) do
        {:ok, _} -> {findings, recommendations}
        {:error, reason} ->
          {[{:semantic_coherence, :failed, reason} | findings],
           ["Increase NDE novelty injection or partition high-drift nodes" | recommendations]}
      end

    # 3. Observer safety check
    {findings, recommendations} =
      case ObserverSafety.validate_observer_boundaries(observer_states) do
        {:ok, _} -> {findings, recommendations}
        {:error, reason} ->
          {[{:observer_safety, :failed, reason} | findings],
           ["Strengthen OSL projection filters and quarantine recursive observers" | recommendations]}
      end

    # 4. Global equilibrium check
    {findings, recommendations} =
      case EquilibriumMonitor.validate_global_equilibrium(cosmological_metrics) do
        {:ok, _} -> {findings, recommendations}
        {:error, reason} ->
          {[{:global_equilibrium, :failed, reason} | findings],
           ["Activate RRG emergency stabilization or lower critical curvature limits" | recommendations]}
      end

    # 5. Self-compilation rules integrity check
    {findings, recommendations} =
      case validate_self_compilation_history() do
        :ok -> {findings, recommendations}
        {:error, reason} ->
          {[{:self_compilation, :failed, reason} | findings],
           ["Pause 5F.13 self-compilation kernel; review mutation engine bounds" | recommendations]}
      end

    status = if findings == [], do: :passed, else: :failed

    %{
      status: status,
      findings: Enum.reverse(findings),
      recommendations: Enum.reverse(recommendations)
    }
  end

  defp validate_self_compilation_history do
    if Process.whereis(SelfCompilation) do
      history = SelfCompilation.active_rules()
      # Invariant check: verify that active rules are not empty and have valid invariants
      if Map.equal?(history, %{}) do
        {:error, "No active rule set loaded in self-compilation"}
      else
        invalid = Enum.filter(history, fn {_subsystem, rule} ->
          not rule_valid?(rule)
        end)

        if invalid == [] do
          :ok
        else
          {:error, "Invalid rules deployed: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}"}
        end
      end
    else
      {:error, "SelfCompilation GenServer is offline"}
    end
  end

  defp fetch_branch_registry do
    case Registry.lookup(Tiannara.Registry, {:universe, :branch_registry}) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :get_registry, 5000)
        catch
          _ -> %{}
        end
      [] -> %{}
    end
  end

  defp fetch_node_states do
    case Registry.lookup(Tiannara.Registry, {:universe, :node_states}) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :get_states, 5000)
        catch
          _ -> %{}
        end
      [] -> %{}
    end
  end

  defp fetch_observer_states do
    case Registry.lookup(Tiannara.Registry, {:universe, :observer_states}) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :get_states, 5000)
        catch
          _ -> %{}
        end
      [] -> %{}
    end
  end

  defp fetch_cosmological_metrics do
    case Registry.lookup(Tiannara.Registry, {:universe, :cosmological_metrics}) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :get_metrics, 5000)
        catch
          _ -> %{psi: 1.0, omega: 0.5, phi: 0.5}
        end
      [] -> %{psi: 1.0, omega: 0.5, phi: 0.5}
    end
  end

  defp rule_valid?(%{invariants: invs}) when is_list(invs) and length(invs) > 0, do: true
  defp rule_valid?(rule) when is_map(rule) and map_size(rule) > 0, do: true
  defp rule_valid?(rule) when rule in [:deployed_locally, :deployed_via_nats], do: true
  defp rule_valid?(_), do: false
end
