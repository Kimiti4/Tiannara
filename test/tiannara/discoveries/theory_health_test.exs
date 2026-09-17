defmodule Tiannara.Discoveries.TheoryHealthTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discoveries.Discovery

  test "calculates aggregate confidence correctly from decomposed scores" do
    disc = %Discovery{
      confidence: %{simulation: 0.90, operational: 0.20, theoretical: 0.80, consensus: 0.70}
    }

    assert Discovery.get_aggregate_confidence(disc) == 0.65
  end

  test "promotion gate check with decomposed confidence scores" do
    # Meets supported law: worlds > 500 and aggregate confidence > 0.75
    disc_ok = %Discovery{
      id: "disc_ok",
      name: "Identity Shift Limit",
      confidence: %{simulation: 0.90, operational: 0.80, theoretical: 0.80, consensus: 0.70}, # average 0.80
      worlds_evidence: 600,
      operational_runs_evidence: 10,
      status: :observation
    }

    {:ok, promoted} = Discovery.promote(disc_ok)
    assert promoted.status == :supported_law

    # Fails supported law: worlds > 500 but aggregate confidence <= 0.75
    disc_fail = %Discovery{
      id: "disc_fail",
      name: "Identity Shift Limit Fail",
      confidence: %{simulation: 0.80, operational: 0.20, theoretical: 0.80, consensus: 0.60}, # average 0.60
      worlds_evidence: 600,
      operational_runs_evidence: 10,
      status: :observation
    }

    assert Discovery.promote(disc_fail) == {:error, :threshold_not_met}
  end

  test "falsification tracking metadata presence" do
    disc = %Discovery{
      falsification_attempts: 10,
      successful_challenges: 2,
      survived_challenges: 8
    }

    assert disc.falsification_attempts == 10
    assert disc.successful_challenges == 2
    assert disc.survived_challenges == 8
  end
end
