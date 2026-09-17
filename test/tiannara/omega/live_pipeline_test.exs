defmodule Tiannara.Omega.LivePipelineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.LivePipeline
  alias Tiannara.Telemetry.Observation

  @moduletag :omega_live_pipeline

  defmodule MockCIProvider do
    def trigger_workflow(_config, _inputs), do: {:ok, :dispatched}
    def find_run_by_correlation(_config, correlation_id), do: {:ok, "run-" <> correlation_id}
    def run_status(_config, _run_id), do: {:ok, :done}
    def run_conclusion(_config, run_id), do: {:ok, {"success for " <> run_id, 0}}
    def cancel_run(_config, _run_id), do: :ok
  end

  defp growing_memory_observations do
    for i <- 1..5,
      do: %Observation{id: i, timestamp: i, source: :test,
                       metrics: %{total_memory: 100 + i * 10}}
  end

  test "closed loop: telemetry anomaly → investigation → proposal → CI validation" do
    result =
      LivePipeline.run_cycle(
        observations: growing_memory_observations(),
        growth_window: 3,
        ci_provider: MockCIProvider,
        ci_config: %{},
        timeout: 1_000,
        poll_interval: 1
      )

    assert length(result.observations) == 5

    # anomaly → epistemic event
    assert length(result.epistemic_events) >= 1
    assert hd(result.epistemic_events).type == :anomaly_detected

    # investigation triggered with hypotheses
    assert result.investigation != nil
    assert length(result.investigation.hypotheses) > 0

    # proposal generated
    assert result.proposal != nil
    assert result.proposal.status == :proposed

    # correlation-aware CI validation
    assert {:ok, ci} = result.ci_validation
    assert ci.run_id == "run-" <> ci.correlation_id

    assert result.verdict == :validated_via_ci
    assert length(result.lineage) >= 3
  end

  test "without CI provider, completes investigation without CI" do
    result = LivePipeline.run_cycle(observations: growing_memory_observations(), growth_window: 3)

    assert result.investigation != nil
    assert result.ci_validation == :ci_not_configured
    assert result.verdict == :investigation_complete_no_ci
  end

  test "no anomaly → no investigation" do
    stable =
      for i <- 1..5,
        do: %Observation{id: i, timestamp: i, source: :test, metrics: %{total_memory: 100}}

    result = LivePipeline.run_cycle(observations: stable, growth_window: 3)

    assert result.epistemic_events == []
    assert result.investigation == nil
    assert result.verdict == :no_investigation_triggered
  end
end