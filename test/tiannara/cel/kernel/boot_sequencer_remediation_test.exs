defmodule Tiannara.CEL.Kernel.BootSequencerRemediationTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.{BootSequencer, ServiceRegistry, ConstitutionalScore}

  defp spec(overrides \\ []) do
    Map.merge(%{
      id: :test_service,
      module: __MODULE__,
      version: "1.0.0",
      criticality: :critical,
      depends_on: [],
      provides: [:declared_capability],
      requires: [],
      health_check: {__MODULE__, :health, []},
      constitutional_score_check: {__MODULE__, :score, []},
      boot_timeout: 1000,
      deprecated: false
    }, Map.new(overrides))
  end

  def capabilities, do: [:other_capability]
  def health, do: :healthy
  def score, do: ConstitutionalScore.default(:test_service)

  test "capability declarations are actually checked" do
    result =
      BootSequencer.boot(
        fn _ -> {:ok, self()} end,
        fn _ -> :healthy end,
        fn _ -> %ConstitutionalScore{
          service_id: :test_service,
          health: 1.0,
          constitutional_alignment: 1.0,
          transparency: 1.0,
          explainability: 1.0,
          evidence_quality: 1.0,
          human_oversight: 1.0,
          computed_at: DateTime.utc_now()
        } end,
        fn _ -> :sufficient end,
        [spec()]
      )

    assert result.status == :failed
    assert result.failed_critical == [:test_service]
    assert result.gate_results.test_service.capability ==
             {:fail, "Declared capabilities not implemented: [:declared_capability]"}
  end

  test "constitutional checker failures fail closed" do
    result =
      BootSequencer.boot(
        fn _ -> {:ok, self()} end,
        fn _ -> :healthy end,
        fn _ -> raise "score unavailable" end,
        fn _ -> :sufficient end,
        [spec()]
      )

    assert result.status == :failed
    assert result.gate_results.test_service.constitution ==
             {:fail, "Constitutional score check raised or threw"}
  end
end
