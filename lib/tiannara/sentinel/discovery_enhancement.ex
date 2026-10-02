defmodule Tiannara.Sentinel.DiscoveryEnhancement do
  @moduledoc """
  Controlled lifecycle for corrections proposed by independent domains.

  A proposed correction never edits the original discovery. It becomes a
  candidate variant with explicit provenance, then must be re-tested and
  independently re-verified before it can supersede or improve the discovery.
  """

  @spec propose(map(), map(), map()) :: {:ok, map()} | {:error, term()}
  def propose(discovery, domain_result, correction)
      when is_map(discovery) and is_map(domain_result) and is_map(correction) do
    with :ok <- validate_correction(correction),
         :ok <- require_independent_domain(domain_result) do
      {:ok, %{
        enhancement_id: "enhancement-#{System.unique_integer([:positive])}",
        discovery_id: Map.get(discovery, :id),
        source_domain: Map.get(domain_result, :domain, Map.get(domain_result, :verification_domain)),
        correction: correction,
        parent_discovery: discovery,
        status: :proposed,
        execution_mode: :not_executed,
        evidence_class: :simulated,
        certification_eligible: false,
        acl_oavl_required: true,
        revalidation_required: true
      }}
    end
  end

  @doc "Evaluate a correction against a controlled baseline/variant experiment."
  @spec evaluate(map(), map(), (map() -> {:ok, map()} | {:error, term()})) :: {:ok, map()} | {:error, term()}
  def evaluate(enhancement, experiment, evaluator) when is_map(enhancement) and is_map(experiment) do
    with :ok <- require_evaluator(evaluator),
         :ok <- validate_experiment(experiment),
         {:ok, result} <- invoke(evaluator, Map.merge(experiment, %{enhancement_id: Map.get(enhancement, :enhancement_id), parent_discovery_id: Map.get(enhancement, :discovery_id)})),
         :ok <- validate_evaluation(result) do
      {:ok, Map.merge(enhancement, %{status: :tested, experiment: experiment, test_result: result, tested_at: DateTime.utc_now(), certification_eligible: false, regression_status: Map.get(result, :regression_status, :unknown)})}
    end
  end

  @spec ready_for_reverification?(map()) :: boolean()
  def ready_for_reverification?(enhancement) when is_map(enhancement) do
    r = Map.get(enhancement, :test_result, %{})
    Map.get(enhancement, :status) == :tested and Map.get(r, :fault_resolved) == true and
      Map.get(r, :regression_status) == :none and Map.get(r, :baseline_comparable) == true and
      Map.get(r, :replication_sufficient) == true and Map.get(r, :counterevidence_checked) == true
  end

  @spec record_test(map(), map()) :: {:ok, map()} | {:error, term()}
  def record_test(enhancement, test_result) when is_map(enhancement) and is_map(test_result) do
    evaluate(enhancement, test_result, fn _ -> {:ok, test_result} end)
  end

  defp validate_correction(correction) do
    if Map.has_key?(correction, :problem) and Map.has_key?(correction, :proposed_change) and
         Map.has_key?(correction, :expected_effect),
      do: :ok,
      else: {:error, :incomplete_domain_correction}
  end

  defp require_independent_domain(result) do
    if Map.get(result, :independent, false) == true and is_atom(Map.get(result, :status)),
      do: :ok,
      else: {:error, :correction_source_not_independently_verified}
  end
  defp require_evaluator(fun) when is_function(fun, 1), do: :ok
  defp require_evaluator(_), do: {:error, :enhancement_evaluator_unavailable}

  defp validate_experiment(experiment) do
    required = [:baseline_id, :variant_id, :controlled_variables, :changed_variables, :seed, :replications]
    case Enum.find(required, &(not Map.has_key?(experiment, &1))) do
      nil when experiment.replications >= 2 -> :ok
      nil -> {:error, :insufficient_replications}
      key -> {:error, {:missing_experiment_field, key}}
    end
  end

  defp invoke(fun, input) do
    case fun.(input) do
      {:ok, result} when is_map(result) -> {:ok, result}
      {:error, reason} -> {:error, {:enhancement_evaluation_failed, reason}}
      other -> {:error, {:invalid_enhancement_evaluation_result, other}}
    end
  rescue
    exception -> {:error, {:enhancement_evaluation_crashed, exception}}
  end

  defp validate_evaluation(result) do
    required = [:fault_resolved, :regression_status, :baseline_comparable, :replication_sufficient, :counterevidence_checked]
    case Enum.find(required, &(not Map.has_key?(result, &1))) do
      nil -> :ok
      key -> {:error, {:missing_evaluation_field, key}}
    end
  end

end
