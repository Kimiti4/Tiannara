defmodule Tiannara.Discovery.EvidenceIntegrator do
  alias Tiannara.Discovery.Domain.DiscoveryResult

  @doc """
  Integrates experiment results into evidence evaluations.
  Groups by experiment, computes aggregate outcomes.
  NEVER calls KnowledgeCoordinator directly - returns evaluation maps.
  """
  @spec integrate([DiscoveryResult.t()], map()) :: [map()]
  def integrate(results, knowledge_state \\ %{}) do
    results
    |> Enum.group_by(& &1.experiment_id)
    |> Enum.map(fn {_exp_id, exp_results} ->
      outcome = compute_outcome(exp_results)
      evidence_items = Enum.flat_map(exp_results, & &1.evidence)
      total_delta = exp_results |> Enum.map(& &1.confidence_delta) |> Enum.sum()

      %{
        experiment_id: hd(exp_results).experiment_id,
        hypothesis_id: hd(exp_results).hypothesis_id,
        outcome: outcome,
        evidence_count: length(evidence_items),
        confidence_delta: total_delta,
        evaluated_at: DateTime.utc_now()
      }
    end)
  end

  @doc """
  Collects evidence for specific hypothesis IDs from knowledge state.
  """
  @spec collect_evidence(String.t(), [String.t()], map()) :: [DiscoveryResult.t()]
  def collect_evidence(_discovery_id, hypothesis_ids, knowledge_state) do
    results = Map.get(knowledge_state, :experiment_results, %{})
    hypothesis_ids
    |> Enum.flat_map(fn hid -> Map.get(results, hid, []) end)
  end

  @doc """
  Evaluates a single result against current knowledge state.
  """
  @spec evaluate_evidence(DiscoveryResult.t(), map()) :: map()
  def evaluate_evidence(%DiscoveryResult{} = result, _knowledge_state) do
    outcome = cond do
      result.outcome == :falsified -> :falsified
      result.outcome == :supported -> :supported
      result.confidence_delta > 0.0 -> :partially_supported
      result.confidence_delta < 0.0 -> :partially_falsified
      true -> :inconclusive
    end
    %{result: result, evaluated_outcome: outcome, adjusted_delta: result.confidence_delta}
  end

  @doc """
  Computes aggregate outcome across multiple results.
  Any falsified -> :falsified, all supported -> :supported, else :inconclusive.
  """
  @spec compute_outcome([DiscoveryResult.t()]) :: :supported | :falsified | :inconclusive
  def compute_outcome(results) when is_list(results) do
    outcomes = Enum.map(results, & &1.outcome)
    cond do
      :falsified in outcomes -> :falsified
      Enum.all?(outcomes, &(&1 == :supported)) -> :supported
      true -> :inconclusive
    end
  end

  @doc """
  Computes confidence delta adjusted by base confidence and experiment count.
  """
  @spec compute_confidence_delta([DiscoveryResult.t()], float(), integer()) :: float()
  def compute_confidence_delta(results, base_confidence, experiment_count) do
    raw_delta = results |> Enum.map(& &1.confidence_delta) |> Enum.sum()
    adjustment = (base_confidence * 0.1) + (experiment_count * 0.05)
    max(-0.5, min(0.5, raw_delta - adjustment))
  end

  @doc """
  Prepares a knowledge promotion payload for KnowledgeCoordinator.
  NEVER calls KnowledgeCoordinator - only prepares the data payload.
  """
  @spec prepare_promotion(DiscoveryResult.t(), map()) :: map()
  def prepare_promotion(%DiscoveryResult{} = result, knowledge_state) do
    %{
      type: :evidence_promotion,
      hypothesis_id: result.hypothesis_id,
      experiment_id: result.experiment_id,
      outcome: result.outcome,
      confidence_delta: result.confidence_delta,
      evidence: result.evidence,
      posterior: result.posterior || 0.5,
      source: :discovery_engine,
      context: %{
        previous_confidence: Map.get(knowledge_state, :confidence, 0.5),
        evidence_count: length(result.evidence),
        evaluated_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Validates a DiscoveryResult struct.
  """
  @spec validate_result(DiscoveryResult.t()) :: :ok | {:error, term()}
  def validate_result(%DiscoveryResult{} = result) do
    cond do
      result.experiment_id == nil -> {:error, :missing_experiment_id}
      result.hypothesis_id == nil -> {:error, :missing_hypothesis_id}
      result.outcome == nil -> {:error, :evidence_missing_outcome}
      result.outcome not in [:supported, :falsified, :inconclusive, :confirmed, :refuted] -> {:error, :invalid_outcome}
      not is_list(result.evidence) -> {:error, :evidence_must_be_list}
      true -> :ok
    end
  end

  @doc """
  Validates a list of evidence results.
  Returns :ok or {:error, reason}.
  """
  @spec validate_evidence([DiscoveryResult.t()]) :: :ok | {:error, atom()}
  def validate_evidence([]), do: {:error, :no_evidence_provided}
  def validate_evidence(results) when is_list(results) do
    errors = results |> Enum.map(&validate_result/1) |> Enum.filter(fn r -> r != :ok end)
    if errors == [], do: :ok, else: hd(errors)
  end

  @doc """
  Processes experiment results and returns action tuples.
  Actions describe what should happen next without calling any service directly.
  """
  @spec process_results(Discovery.t(), [DiscoveryResult.t()]) :: [tuple()]
  def process_results(disc, results) when is_list(results) do
    outcome = aggregate_outcome(results)
    delta = aggregate_confidence_delta(results)

    cond do
      outcome in [:refuted, :falsified] ->
        [{:record_conflict, outcome}, {:update_discovery, disc.id, %{confidence: max(0.0, disc.confidence + delta)}}]
      outcome in [:confirmed, :supported] and delta > 0.0 ->
        [{:fuse_evidence, disc.id, length(results), delta},
         {:update_discovery, disc.id, %{confidence: min(1.0, disc.confidence + delta)}},
         {:promote_knowledge, disc.id, outcome}]
      true ->
        [{:fuse_evidence, disc.id, length(results), delta},
         {:update_discovery, disc.id, %{confidence: disc.confidence}}]
    end
  end

  @doc """
  Aggregates outcomes across results.
  Any refuted/falsified -> :refuted, all confirmed/supported -> :confirmed, else :inconclusive.
  """
  @spec aggregate_outcome([DiscoveryResult.t()]) :: atom()
  def aggregate_outcome([]), do: :inconclusive
  def aggregate_outcome(results) when is_list(results) do
    outcomes = Enum.map(results, &normalize_outcome(&1.outcome))
    cond do
      :refuted in outcomes -> :refuted
      Enum.all?(outcomes, &(&1 == :confirmed)) -> :confirmed
      true -> :inconclusive
    end
  end

  @doc """
  Sums confidence deltas across all results.
  """
  @spec aggregate_confidence_delta([DiscoveryResult.t()]) :: float()
  def aggregate_confidence_delta(results) when is_list(results) do
    Enum.reduce(results, 0.0, fn r, acc -> acc + (r.confidence_delta || 0.0) end)
  end

  defp normalize_outcome(:supported), do: :confirmed
  defp normalize_outcome(:confirmed), do: :confirmed
  defp normalize_outcome(:falsified), do: :refuted
  defp normalize_outcome(:refuted), do: :refuted
  defp normalize_outcome(_), do: :inconclusive
end
