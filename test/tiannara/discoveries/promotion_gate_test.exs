defmodule Tiannara.Discoveries.PromotionGateTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discoveries.Discovery

  test "promotion gate check: supported_law success" do
    disc = %Discovery{
      id: "disc1",
      name: "Decay Speedup",
      confidence: 0.80,
      worlds_evidence: 600,
      operational_runs_evidence: 10,
      claim: "Fast decay enhances resilience",
      status: :observation
    }

    {:ok, promoted} = Discovery.promote(disc)
    assert promoted.status == :supported_law
  end

  test "promotion gate check: candidate_law success" do
    disc = %Discovery{
      id: "disc2",
      name: "Identity Anchor",
      confidence: 0.65,
      worlds_evidence: 120,
      operational_runs_evidence: 5,
      claim: "Static identity stabilizes system",
      status: :observation
    }

    {:ok, promoted} = Discovery.promote(disc)
    assert promoted.status == :candidate_law
  end

  test "promotion gate check: validated success" do
    disc = %Discovery{
      id: "disc3",
      name: "Causal Loop Prevention",
      confidence: 0.50,
      worlds_evidence: 50,
      operational_runs_evidence: 60,
      claim: "Loop detection prevents stack collapse",
      status: :observation
    }

    {:ok, promoted} = Discovery.promote(disc)
    assert promoted.status == :validated
  end

  test "promotion gate check: threshold not met fails" do
    disc = %Discovery{
      id: "disc4",
      name: "Unknown Phenomenon",
      confidence: 0.50,
      worlds_evidence: 80,
      operational_runs_evidence: 10,
      claim: "None",
      status: :observation
    }

    assert Discovery.promote(disc) == {:error, :threshold_not_met}
  end
end
