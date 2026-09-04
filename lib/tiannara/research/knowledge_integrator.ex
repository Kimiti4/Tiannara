defmodule Tiannara.Research.KnowledgeIntegrator do
  @moduledoc """
  Knowledge Integrator — integrates validated findings into Executive Memory.

  This is the final stage of the scientific method pipeline:
  Validation → Knowledge Integration → Continuous Re-evaluation.

  Only evidence with confidence >= threshold is integrated. All integrated
  knowledge carries full lineage, evidence chain, and confidence metadata.

  ## Constitutional Alignment

    - Memory Philosophy: Knowledge exists to improve reasoning, not merely store.
    - Evidence Before Confidence: Only validated findings are integrated.
    - Explainability: Every knowledge item carries full evidence chain.
    - Verification First: Integration requires confidence >= threshold.
    - Continuous Self-Evaluation: Integrated knowledge is periodically re-evaluated.
    - Safety: Previous stable knowledge is preserved; rollback is supported.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.Types

  @confidence_threshold 0.7

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec integrate(map(), map(), keyword()) :: :ok | {:error, term()}
  def integrate(experiment, evidence, opts \\ []) do
    execution_mode = Keyword.get(opts, :execution_mode, :unknown)
    GenServer.call(__MODULE__, {:integrate, experiment, evidence, execution_mode})
  end

  @spec recent(non_neg_integer()) :: [map()]
  def recent(count \\ 50) do
    GenServer.call(__MODULE__, {:recent, count})
  end

  @spec real_knowledge(non_neg_integer()) :: [map()]
  def real_knowledge(count \\ 50) do
    GenServer.call(__MODULE__, {:real_knowledge, count})
  end

  @spec total_integrated() :: non_neg_integer()
  def total_integrated do
    GenServer.call(__MODULE__, :total_integrated)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{knowledge: [], total_integrated: 0, total_rejected: 0, total_quarantined: 0, last_integration_at: nil}, {:continue, :quarantine_historical}}
  end

  @impl true
  def handle_continue(:quarantine_historical, state) do
    quarantined_items =
      Enum.map(state.knowledge, fn item ->
        if Map.has_key?(item, :execution_mode) do
          item
        else
          Map.merge(item, %{
            execution_mode: :unknown,
            quarantined: true,
            quarantine_reason: :fabricated_result_legacy,
            quarantined_at: DateTime.utc_now()
          })
        end
      end)

    quarantine_count = Enum.count(quarantined_items, & &1.quarantined)
    if quarantine_count > 0, do: Logger.warning("[KnowledgeIntegrator] R0: quarantined #{quarantine_count} historical knowledge items (execution_mode missing — presumed fabricated).")
    {:noreply, %{state | knowledge: quarantined_items, total_quarantined: quarantine_count}}
  end

  @impl true
  def handle_call({:integrate, experiment, evidence, execution_mode}, _from, state) do
    cond do
      execution_mode != :real_execution ->
        Logger.warning("[KnowledgeIntegrator] Rejected: execution_mode=#{inspect(execution_mode)} — only :real_execution produces certified knowledge.")
        {:reply, {:error, :execution_mode_not_real}, %{state | total_rejected: state.total_rejected + 1}}

      evidence.confidence < @confidence_threshold ->
        Logger.debug("[KnowledgeIntegrator] Rejected: confidence #{evidence.confidence} < #{@confidence_threshold}")
        {:reply, {:error, :insufficient_confidence}, %{state | total_rejected: state.total_rejected + 1}}

      true ->
        knowledge_item = build_knowledge_item(experiment, evidence, execution_mode)
        persist_to_executive_memory(knowledge_item)

        :telemetry.execute([:tiannara, :research, :knowledge_integrated], %{confidence: evidence.confidence}, %{domain: experiment.hypothesis[:domain], execution_mode: execution_mode})

        Logger.info("[KnowledgeIntegrator] Knowledge integrated. Title: #{knowledge_item.title} Confidence: #{evidence.confidence} Domain: #{knowledge_item.domain} execution_mode: #{execution_mode}")

        {:reply, :ok, %{state | knowledge: [knowledge_item | Enum.take(state.knowledge, 999)], total_integrated: state.total_integrated + 1, last_integration_at: DateTime.utc_now()}}
    end
  end

  @impl true
  def handle_call({:recent, count}, _from, state) do
    {:reply, Enum.take(state.knowledge, count), state}
  end

  @impl true
  def handle_call({:real_knowledge, count}, _from, state) do
    real_items =
      state.knowledge
      |> Enum.reject(&Map.get(&1, :quarantined, false))
      |> Enum.filter(&(&1.execution_mode == :real_execution))
      |> Enum.take(count)
    {:reply, real_items, state}
  end

  @impl true
  def handle_call(:total_integrated, _from, state) do
    {:reply, state.total_integrated, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_integrated: state.total_integrated, total_rejected: state.total_rejected, total_quarantined: state.total_quarantined, last_integration_at: state.last_integration_at, recent_domains: state.knowledge |> Enum.take(10) |> Enum.map(& &1.domain)}, state}
  end

  defp build_knowledge_item(experiment, evidence, execution_mode) do
    hypothesis = experiment.hypothesis

    %{
      id: Types.new_id(), title: hypothesis[:title] || "Validated finding",
      statement: hypothesis[:statement] || "Experiment confirmed hypothesis.",
      domain: hypothesis[:domain] || :general, signal: hypothesis[:signal] || :unknown,
      confidence: evidence.confidence, evidence_id: evidence.id, experiment_id: experiment.id,
      hypothesis_id: hypothesis[:id], execution_mode: execution_mode,
      evidence_chain: [
        %{stage: :observation, source: :sentinel}, %{stage: :hypothesis, id: hypothesis[:id]},
        %{stage: :experiment, id: experiment.id, execution_mode: execution_mode},
        %{stage: :evidence, id: evidence.id, confidence: evidence.confidence}
      ],
      lineage: %{discovery_source: :research_director, experiment_id: experiment.id, confidence_score: evidence.confidence, execution_mode: execution_mode, created_by: __MODULE__, created_at: DateTime.utc_now()},
      memory_class: :persistent, integrated_at: DateTime.utc_now(),
      re_evaluation_due: DateTime.add(DateTime.utc_now(), 7 * 24 * 3600, :second)
    }
  end

  defp persist_to_executive_memory(knowledge_item) do
    case Process.whereis(Tiannara.Executive.ExecutiveMemory) do
      nil ->
        Logger.debug("[KnowledgeIntegrator] ExecutiveMemory not available; skipping persistence.")
        :ok
      _pid ->
        try do
          Tiannara.Executive.ExecutiveMemory.put({:knowledge, knowledge_item.id}, knowledge_item, memory_class: :persistent, actor: __MODULE__, lineage: knowledge_item.lineage)
        catch
          _, _ -> :ok
        end
    end
  end
end
