defmodule Tiannara.Sentinel.Validation.AdversarialCaseGenerator do
  @moduledoc """
  Generates pathological cases to test the edge-case behavior of the Observatory Mesh.
  """

  def generate_suite do
    [
      %{
        id: "adv_sparse_telemetry",
        type: :type_a_runtime_pressure,
        expected_best_action: :observation_only, # Not enough data to act safely
        worst_possible_action: :constraint_tightening,
        pathology: :sparse_telemetry
      },
      %{
        id: "adv_novel_anomaly",
        type: :type_f_unknown_emergence,
        expected_best_action: :quarantine,
        worst_possible_action: :entropy_rebalancing,
        pathology: :novel_type
      },
      %{
        id: "adv_misleading_baseline",
        type: :type_b_entropy_growth,
        expected_best_action: :observation_only, # Growth is actually expected here
        worst_possible_action: :entropy_rebalancing,
        pathology: :misleading_baseline
      }
    ]
  end
end
