defmodule Tiannara.Audits.Checkpoint1910HAINegativeRegressionTest do
  use ExUnit.Case, async: false

  alias Tiannara.HAI.Domain.ReviewRequest
  alias Tiannara.HAI.ReviewRouter

  setup do
    pid = Process.whereis(ReviewRouter)
    assert is_pid(pid), "ReviewRouter must be started by the application"

    :sys.replace_state(pid, fn _ ->
      %{
        reviews: %{},
        total_submitted: 0,
        total_approved: 0,
        total_rejected: 0,
        total_modified: 0,
        total_deferred: 0,
        total_expired: 0,
        mandatory_count: 0,
        healthy: true,
        started_at: DateTime.utc_now()
      }
    end)

    :ok
  end

  test "missing or unrecognized impact cannot be auto-approved" do
    missing_impact = base_attrs(:low) |> Map.delete(:impact_level)

    for attrs <- [
          missing_impact,
          base_attrs(nil),
          base_attrs(:unrecognized),
          base_attrs("critical")
        ] do
      result = ReviewRouter.submit_review(attrs)

      refute match?({:ok, %ReviewRequest{status: :approved}}, result),
             "invalid or absent impact was auto-approved: #{inspect(attrs[:impact_level])}"
    end
  end

  test "a caller without reviewer identity cannot resolve a mandatory review" do
    {:ok, request} = ReviewRouter.submit_review(base_attrs(:high))

    result = ReviewRouter.record_decision(request.id, :approved, "No authenticated reviewer")

    refute result == :ok,
           "ReviewRouter accepted a decision without reviewer identity or authorization"
  end

  test "unsupported decision values are rejected" do
    {:ok, request} = ReviewRouter.submit_review(base_attrs(:high))

    result = ReviewRouter.record_decision(request.id, :promote_without_review, "invalid enum")

    refute result == :ok,
           "ReviewRouter accepted an unsupported decision value"
  end

  test "a resolved review cannot be decided again" do
    {:ok, request} = ReviewRouter.submit_review(base_attrs(:high))
    assert :ok = ReviewRouter.record_decision(request.id, :approved, "first decision")

    result = ReviewRouter.record_decision(request.id, :rejected, "conflicting replay")

    refute result == :ok,
           "ReviewRouter accepted a second, conflicting decision for the same review"
  end

  defp base_attrs(impact_level) do
    %{
      source_subsystem: :checkpoint_19_10,
      decision_type: :negative_regression,
      summary: "Checkpoint 19.10 HAI negative regression",
      impact_level: impact_level,
      confidence: 0.5,
      uncertainty: 0.5,
      evidence_summary: "Test fixture only",
      alternatives: [],
      recommendation: :require_human_decision
    }
  end
end
