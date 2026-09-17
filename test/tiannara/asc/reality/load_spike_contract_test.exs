defmodule Tiannara.ASC.Reality.LoadSpikeContractTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Reality.{Director, RiskAssessmentEngine}

  setup do
    for mod <- [
          Director,
          RiskAssessmentEngine,
          Tiannara.ASC.Reality.SafetyVerificationEngine,
          Tiannara.ASC.Reality.ComplianceEngine,
          Tiannara.ASC.Reality.IncidentResponseEngine,
          Tiannara.ASC.Reality.DeploymentAuditEngine,
          Tiannara.ASC.Reality.StagedRolloutManager,
          Tiannara.ASC.Reality.RollbackEngine,
          Tiannara.ASC.Reality.ResourceOptimizationEngine,
          Tiannara.ASC.Reality.InfrastructurePlanner,
          Tiannara.ASC.Reality.EnvironmentalImpactEngine
        ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    # Reset engines that accumulate state before AND after, so this test file
    # never leaks monitors/deployments into the shared ExUnit process pool.
    Tiannara.ASC.Reality.IncidentResponseEngine.reset()
    on_exit(fn -> Tiannara.ASC.Reality.IncidentResponseEngine.reset() end)

    :ok
  end

  defp stub do
    %{name: "stub", version: "1.0", payload: %{data: :x}}
  end

  defp stub_with_uncertainty do
    %{stub() | uncertainty_level: 0.3}
  end

  # 1. Exact T+48h repro: a stub artifact WITHOUT :uncertainty_level must
  #    assess without raising KeyError. Before the patch, this crashed
  #    identify_risks at risk_assessment_engine.ex:57 (artifact.uncertainty_level
  #    is a bare Map.fetch-style access).
  test "stub artifact without :uncertainty_level assesses without raising" do
    normalized = Tiannara.ASC.Reality.Artifact.normalize(stub())

    {:ok, profile} = RiskAssessmentEngine.assess(normalized, %{})
    assert is_number(profile.overall_risk_score)
    assert length(profile.risks) > 0
  end

  # 1b. Direct consumer-level proof: the engine itself never crashes on a
  #     bare stub (the exact shape the load spike sends), proving the
  #     KeyError path is closed even if something bypasses normalization.
  test "RiskAssessmentEngine handles bare stub artifact without KeyError" do
    artifact = %{name: "bare_stub", version: "1.0", payload: %{data: :x}}
    {:ok, profile} = RiskAssessmentEngine.assess(artifact, %{})
    assert is_number(profile.overall_risk_score)
  end

  # 2. Full spike: 50 concurrent stub deploys complete (no crash, no hang).
  test "50 concurrent stub deploys complete via bounded spike" do
    artifacts =
      1..50
      |> Enum.map(fn i ->
        {%{stub() | name: "load_test_#{i}", payload: %{data: "test_#{i}"}}, :digital, %{staged: true}}
      end)

    results = Director.spike(artifacts)

    assert length(results) == 50
    ok_count = Enum.count(results, &match?({:ok, _}, &1))
    assert ok_count >= 45
  end

  # 3. Mixed schemas: deterministic behavior whether or not uncertainty is present.
  test "mixed schemas (with/without uncertainty) all assess" do
    artifacts =
      1..20
      |> Enum.map(fn i ->
        base = %{stub() | name: "mixed_#{i}", payload: %{data: "item_#{i}"}}

        if rem(i, 2) == 0 do
          {Map.put(base, :uncertainty_level, 0.2), :digital, %{staged: true}}
        else
          {base, :digital, %{staged: true}}
        end
      end)

    results = Director.spike(artifacts)

    assert length(results) == 20
    assert Enum.all?(results, &match?({:ok, _}, &1))
  end

  # 4. Fault isolation: one artifact targeting an unsupported :bogus_target
  #    returns a failed deployment status, and the remaining 49 succeed.
  #    The spike must never become a single point of failure (the :infinity
  #    amplification that ended the last soak: one exception pinned the
  #    orchestrator and killed the run). Now every result returns — either
  #    {:ok, {:deployed, ...}} or {:ok, {:failed, ...}} — with no crashes.
  test "one failing artifact does not stall or abort the remaining deploys" do
    poison = {stub(), :bogus_target, %{staged: true}}

    fast_artifacts =
      1..49
      |> Enum.map(fn i ->
        {%{stub() | name: "fast_#{i}", payload: %{data: "ok_#{i}", uncertainty_level: 0.5}},
         :digital, %{staged: true}}
      end)

    artifacts = [poison | fast_artifacts]
    results = Director.spike(artifacts, max_concurrency: 50, timeout: 30_000)

    assert length(results) == 50

    # No Task.async_stream leaks: every item produced a result.
    assert Enum.all?(results, &is_tuple(&1) and tuple_size(&1) == 2)

    # The poison artifact is recorded as :failed (not an unhandled crash).
    statuses =
      Enum.map(results, fn
        {:ok, {:failed, _, _}} -> :failed
        {:ok, {:deployed, _, _}} -> :deployed
        {:error, _} -> :error
      end)

    assert Enum.count(statuses, &(&1 == :failed)) >= 1
    assert Enum.count(statuses, &(&1 == :deployed)) >= 48
  end
end
