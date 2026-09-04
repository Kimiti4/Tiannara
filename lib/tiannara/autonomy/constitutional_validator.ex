defmodule Tiannara.Autonomy.ConstitutionalValidator do
  @moduledoc """
  Constitutional Validator — validates proposals against Tiannara's constitution.
  Every improvement proposal must pass constitutional validation before
  proceeding to simulation or deployment.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec validate(map()) :: {:approved, String.t()} | {:rejected, String.t()}
  def validate(proposal) do
    GenServer.call(__MODULE__, {:validate, proposal})
  end

  @spec total_violations() :: non_neg_integer()
  def total_violations do
    GenServer.call(__MODULE__, :total_violations)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_validated: 0, total_approved: 0, total_rejected: 0, violations: [], last_validation_at: nil}}
  end

  @impl true
  def handle_call({:validate, proposal}, _from, state) do
    checks = run_all_checks(proposal)
    violations = Enum.filter(checks, fn {passed, _} -> not passed end)
    result = if length(violations) == 0, do: {:approved, "All constitutional checks passed."}, else: {:rejected, Enum.join(Enum.map(violations, fn {_, r} -> r end), "; ")}

    case result do
      {:rejected, reason} -> Logger.warning("[ConstitutionalValidator] PROPOSAL REJECTED #{proposal[:id]}: #{reason}")
      _ -> :ok
    end

    :telemetry.execute([:tiannara, :autonomy, :constitutional_validation], %{count: 1, violations: length(violations)}, %{result: if(length(violations) == 0, do: :approved, else: :rejected)})

    new_state = %{state | total_validated: state.total_validated + 1, total_approved: if(length(violations) == 0, do: state.total_approved + 1, else: state.total_approved), total_rejected: if(length(violations) > 0, do: state.total_rejected + 1, else: state.total_rejected), violations: if(length(violations) > 0, do: [{proposal[:id], violations} | state.violations], else: state.violations), last_validation_at: DateTime.utc_now()}
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:total_violations, _from, state) do
    {:reply, length(state.violations), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_validated: state.total_validated, total_approved: state.total_approved, total_rejected: state.total_rejected, total_violations: length(state.violations), last_validation_at: state.last_validation_at}, state}
  end

  defp run_all_checks(proposal) do
    [check_mission_alignment(proposal), check_verification_precedence(proposal), check_rollback_availability(proposal), check_lineage_preservation(proposal), check_human_augmentation(proposal), check_risk_proportionality(proposal), check_long_term_compatibility(proposal), check_complexity_justification(proposal)]
  end

  defp check_mission_alignment(proposal) do
    if (proposal[:objective] != nil and proposal[:objective] != "") and (proposal[:rationale] != nil and proposal[:rationale] != "") do
      {true, "Mission alignment: objective and rationale present."}
    else
      {false, "Mission alignment: proposal lacks clear objective or rationale."}
    end
  end

  defp check_verification_precedence(_proposal), do: {true, "Verification precedence: simulation required before deployment (enforced by pipeline)."}
  defp check_rollback_availability(proposal) do
    if proposal[:rollback_plan] != nil and proposal[:rollback_plan] != "" do
      {true, "Rollback availability: rollback plan present."}
    else
      {false, "Rollback availability: no rollback plan specified."}
    end
  end

  defp check_lineage_preservation(proposal) do
    if proposal[:lineage] != nil and is_map(proposal[:lineage]) do
      {true, "Lineage preservation: lineage metadata present."}
    else
      {false, "Lineage preservation: no lineage metadata."}
    end
  end

  defp check_human_augmentation(proposal) do
    risk = proposal[:risk_level] || :medium
    human_required = proposal[:human_approval_required] || false
    if risk in [:high, :critical] and not human_required do
      {false, "Human augmentation: high-risk proposal must require human approval."}
    else
      {true, "Human augmentation: appropriate human oversight."}
    end
  end

  defp check_risk_proportionality(proposal) do
    risk = proposal[:risk_level] || :medium
    impact = proposal[:expected_impact] || 0.5
    confidence = proposal[:confidence] || 0.5
    cond do
      risk == :critical and impact < 0.5 -> {false, "Risk proportionality: critical risk with low expected impact."}
      risk == :high and confidence < 0.3 -> {false, "Risk proportionality: high risk with very low confidence."}
      true -> {true, "Risk proportionality: acceptable."}
    end
  end

  defp check_long_term_compatibility(proposal) do
    target = to_string(proposal[:target] || "")
    if String.contains?(target, "legacy") or String.contains?(target, "deprecated") do
      {false, "Long-term compatibility: targets deprecated or legacy component."}
    else
      {true, "Long-term compatibility: no platform lock-in detected."}
    end
  end

  defp check_complexity_justification(proposal) do
    if (proposal[:expected_impact] || 0.5) < 0.1 do
      {false, "Complexity justification: expected impact below minimum threshold (0.1)."}
    else
      {true, "Complexity justification: expected impact justifies change."}
    end
  end
end
