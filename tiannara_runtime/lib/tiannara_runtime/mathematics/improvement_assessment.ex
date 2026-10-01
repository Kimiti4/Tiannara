defmodule TiannaraRuntime.Mathematics.ImprovementAssessment do
  @moduledoc """
  Evidence-bound assessment of proposed self-improvements.

  Mathematical merit is never sufficient for implementation. The assessment
  separates necessity, mathematical evidence, cross-system impact, regression,
  safety, ACL/OAVL/CEL governance, and final human authorization.
  """

  @required_checks [:necessity, :mathematical_validity, :system_impact, :regression,
                    :safety, :acl, :oavl, :cel, :human_authorization]

  def assess(proposal, evidence) when is_map(proposal) and is_map(evidence) do
    results = Enum.map(@required_checks, fn check -> {check, Map.get(evidence, check, :missing)} end)

    status =
      cond do
        Enum.any?(results, fn {_k, v} -> v in [:fail, :unsafe, :regression_detected] -> end) ->
          :rejected
        Enum.any?(results, fn {_k, v} -> v in [:missing, :unknown, :inconclusive] -> end) ->
          :blocked_pending_evidence
        Enum.all?(results, fn {_k, v} -> v == :pass end) ->
          :ready_for_human_authorization
        true -> :blocked
      end

    {:ok, %{proposal: proposal, checks: results, status: status,
            implementation_allowed: false, required_checks: @required_checks}}
  end

  def assess(_, _), do: {:error, :improvement_assessment_requires_maps}
end
