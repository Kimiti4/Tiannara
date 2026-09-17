defmodule Tiannara.Operations.ChallengeDiagnosticsTest do
  use ExUnit.Case, async: true

  defp record(challenge, passed, at_offset \\ 0) do
    %{challenge: challenge, passed: passed, at: DateTime.add(DateTime.utc_now(), at_offset)}
  end

  test "classifies a fully passing challenge as healthy" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        record(:anomaly_detection, true, 0),
        record(:anomaly_detection, true, 1)
      ])

    assert result.anomaly_detection.classification == :healthy
    assert result.anomaly_detection.passes == 2
    assert result.anomaly_detection.attempts == 2
    assert result.anomaly_detection.confidence_note =~ "reliable"
  end

  test "classifies a failure on the first run then recovery as timing" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        record(:anomaly_detection, false, 0),
        record(:anomaly_detection, true, 1)
      ])

    assert result.anomaly_detection.classification == :timing
  end

  test "classifies a single isolated mid-run failure as transient" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        record(:anomaly_detection, true, 0),
        record(:anomaly_detection, false, 1),
        record(:anomaly_detection, true, 2)
      ])

    assert result.anomaly_detection.classification == :transient
  end

  test "classifies two consecutive failures as repeatable with downgraded confidence" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        record(:anomaly_detection, false, 0),
        record(:anomaly_detection, false, 1),
        record(:anomaly_detection, true, 2)
      ])

    assert result.anomaly_detection.classification == :repeatable
    assert result.anomaly_detection.confidence_note =~ "downgraded"
  end

  test "classifies liveness challenge failure as environmental" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        record(:causal_lineage_integrity, true, 0),
        record(:causal_lineage_integrity, false, 1)
      ])

    assert result.causal_lineage_integrity.classification == :environmental
    assert result.causal_lineage_integrity.liveness_check == true
  end

  test "classifies an unrecovered isolated failure as unknown with downgraded confidence" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([record(:anomaly_detection, false, 0)])

    assert result.anomaly_detection.classification == :unknown
    assert result.anomaly_detection.confidence_note =~ "downgraded"
  end

  test "normalizes engine string challenge ids onto the atom contract" do
    result =
      Tiannara.Operations.ChallengeDiagnostics.diagnose([
        %{
          name: "causal_lineage",
          pass: true,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        },
        %{
          name: "cross_domain_synthesis",
          pass: false,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        }
      ])

    assert result.causal_lineage_integrity.classification == :healthy
    assert result.cross_domain_synthesis.classification == :environmental
  end

  test "empty input yields an empty diagnosis" do
    assert Tiannara.Operations.ChallengeDiagnostics.diagnose([]) == %{}
  end
end
