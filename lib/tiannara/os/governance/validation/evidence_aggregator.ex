defmodule TiannaraOS.Governance.Validation.EvidenceAggregator do
  @moduledoc """
  EvidenceAggregator - Combines individual campaign results into overall assessment.
  
  This module aggregates evidence artifacts from all campaigns and produces
  a validation summary with pass/fail counts and freeze recommendation.
  """

  @type evidence_artifact :: map()
  @type validation_summary :: map()

  @doc """
  Aggregate results from all campaign executions.
  """
  @spec aggregate_results([evidence_artifact()]) :: validation_summary()
  def aggregate_results(artifacts) do
    {passed, failed} = Enum.split_with(artifacts, fn artifact ->
      Map.get(artifact, :content_hash) != nil  # Has been signed = passed
    end)
    
    %{
      overall_status: determine_overall_status(passed, failed),
      total_campaigns: length(artifacts),
      passed_campaigns: length(passed),
      failed_campaigns: length(failed),
      critical_failures: identify_critical_failures(failed),
      warning_failures: identify_warning_failures(failed),
      freeze_recommendation: determine_freeze_recommendation(passed, failed),
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Determine overall status from results.
  """
  @spec determine_overall_status([evidence_artifact()], [evidence_artifact()]) :: :pass | :fail | :partial
  def determine_overall_status(_passed, []), do: :pass
  def determine_overall_status([], _failed), do: :fail
  def determine_overall_status(_, _), do: :partial

  @doc """
  Determine whether to freeze governance based on results.
  """
  @spec determine_freeze_recommendation([evidence_artifact()], [evidence_artifact()]) :: :freeze | :do_not_freeze
  def determine_freeze_recommendation(_passed, []), do: :freeze
  def determine_freeze_recommendation(_, _failed), do: :do_not_freeze

  defp identify_critical_failures(failed) do
    # Filter for critical severity failures
    Enum.filter(failed, fn _f -> true end)  # Simplified
  end

  defp identify_warning_failures(_failed) do
    # Filter for warning severity failures
    []
  end
end
