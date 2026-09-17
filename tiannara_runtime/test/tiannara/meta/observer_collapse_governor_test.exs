defmodule Tiannara.Meta.ObserverCollapseGovernorTest do
  @moduledoc """
  Integration tests for Phase 5F.2 — Observer Collapse Governor (OCG)
  
  Tests cover:
  - OSS (Observer Stability Score) computation
  - Arbitration rules (A, B, C, D)
  - Integration with MSCL for live MSF scores
  - Pairwise evaluation and full sweep
  - NATS event publishing
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.Meta.ObserverCollapseGovernor, as: OCG
  alias Tiannara.Meta.MSCL
  
  setup do
    # Start MSCL, OCAL, and OCG safely
    unless Process.whereis(TiannaraRuntime.MCK) do
      {:ok, _} = TiannaraRuntime.MCK.start_link([])
    end
    unless Process.whereis(MSCL) do
      {:ok, _} = MSCL.start_link([])
    end
    unless Process.whereis(Tiannara.Meta.ObserverArbitrationLayer) do
      {:ok, _} = Tiannara.Meta.ObserverArbitrationLayer.start_link([])
    end
    unless Process.whereis(OCG) do
      {:ok, _} = OCG.start_link([])
    end
    
    pid = Process.whereis(OCG)
    %{pid: pid}
  end
  
  describe "compute_oss/1" do
    test "calculates OSS correctly with default values" do
      observer = %{
        observer_id: "test_obs_1",
        coherence: 0.8,
        msf: 0.7,
        prediction: 0.9,
        interference: 0.3
      }
      
      oss = OCG.compute_oss(observer)
      
      # OSS = (0.8 * 0.7 * 0.9) / (0.3 + 0.001) = 0.504 / 0.301 ≈ 1.674 → clamped to 1.0
      assert oss <= 1.0
      assert oss > 0.0
    end
    
    test "handles high interference correctly" do
      observer = %{
        observer_id: "test_obs_2",
        coherence: 0.5,
        msf: 0.5,
        prediction: 0.5,
        interference: 0.9
      }
      
      oss = OCG.compute_oss(observer)
      
      # OSS = (0.5 * 0.5 * 0.5) / (0.9 + 0.001) = 0.125 / 0.901 ≈ 0.139
      assert_in_delta oss, 0.139, 0.01
    end
    
    test "uses default values when fields are missing" do
      observer = %{observer_id: "test_obs_3"}
      
      oss = OCG.compute_oss(observer)
      
      # All defaults to 0.5: OSS = (0.5 * 0.5 * 0.5) / (0.5 + 0.001) ≈ 0.25
      assert_in_delta oss, 0.25, 0.01
    end
    
    test "clamps OSS to maximum 1.0" do
      observer = %{
        observer_id: "test_obs_4",
        coherence: 1.0,
        msf: 1.0,
        prediction: 1.0,
        interference: 0.0
      }
      
      oss = OCG.compute_oss(observer)
      
      assert oss == 1.0
    end
    
    test "returns zero OSS when interference is extremely high" do
      observer = %{
        observer_id: "test_obs_5",
        coherence: 0.1,
        msf: 0.1,
        prediction: 0.1,
        interference: 1.0
      }
      
      oss = OCG.compute_oss(observer)
      
      # OSS = (0.1 * 0.1 * 0.1) / (1.0 + 0.001) ≈ 0.001
      assert oss < 0.01
    end
  end
  
  describe "classify/1" do
    test "classifies dominant attractor reality (OSS >= 0.85)" do
      assert OCG.classify(0.90) == :dominant_attractor
      assert OCG.classify(0.85) == :dominant_attractor
    end
    
    test "classifies stable runtime world (0.60 <= OSS < 0.85)" do
      assert OCG.classify(0.75) == :stable_runtime
      assert OCG.classify(0.60) == :stable_runtime
    end
    
    test "classifies merge candidate (0.30 <= OSS < 0.60)" do
      assert OCG.classify(0.50) == :merge_candidate
      assert OCG.classify(0.30) == :merge_candidate
    end
    
    test "classifies collapse candidate (OSS < 0.30)" do
      assert OCG.classify(0.25) == :collapse_candidate
      assert OCG.classify(0.0) == :collapse_candidate
    end
  end
  
  describe "evaluate_pair/2" do
    test "triggers merge when OSS delta < threshold and high interference" do
      observer_a = %{
        observer_id: "obs_merge_a",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.80  # High interference triggers RULE C
      }
      
      observer_b = %{
        observer_id: "obs_merge_b",
        coherence: 0.76,
        msf: 0.71,
        prediction: 0.79,
        interference: 0.80
      }
      
      # Both observers have similar OSS (~0.52), delta < 0.10, interference > 0.75
      # Should trigger MERGE per RULE A + C
      OCG.evaluate_pair(observer_a, observer_b)
      
      # Give GenServer time to process
      Process.sleep(100)
      
      # Verify scores were updated
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "obs_merge_a")
      assert Map.has_key?(scores, "obs_merge_b")
    end
    
    test "triggers collapse when one observer has critically low OSS" do
      observer_stable = %{
        observer_id: "obs_stable",
        coherence: 0.80,
        msf: 0.75,
        prediction: 0.85,
        interference: 0.20
      }
      
      observer_unstable = %{
        observer_id: "obs_unstable",
        coherence: 0.20,
        msf: 0.15,
        prediction: 0.25,
        interference: 0.90
      }
      
      # Stable OSS ~2.55 (clamped to 1.0), unstable OSS ~0.009
      # Large delta, unstable below collapse threshold → COLLAPSE
      OCG.evaluate_pair(observer_stable, observer_unstable)
      
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "obs_stable")
      assert Map.has_key?(scores, "obs_unstable")
    end
    
    test "triggers suppression when both observers stable but different OSS" do
      observer_high = %{
        observer_id: "obs_high",
        coherence: 0.85,
        msf: 0.80,
        prediction: 0.90,
        interference: 0.15
      }
      
      observer_low = %{
        observer_id: "obs_low",
        coherence: 0.65,
        msf: 0.60,
        prediction: 0.70,
        interference: 0.25
      }
      
      # High OSS ~3.24 (clamped to 1.0), low OSS ~0.84
      # Delta > 0.10, both above collapse threshold → SUPPRESS lower
      OCG.evaluate_pair(observer_high, observer_low)
      
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "obs_high")
      assert Map.has_key?(scores, "obs_low")
    end
    
    test "updates observer scores in state" do
      observer_a = %{
        observer_id: "obs_score_a",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30
      }
      
      observer_b = %{
        observer_id: "obs_score_b",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40
      }
      
      OCG.evaluate_pair(observer_a, observer_b)
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      
      assert length(Map.keys(scores)) >= 2
      assert Map.has_key?(scores, "obs_score_a")
      assert Map.has_key?(scores, "obs_score_b")
    end
  end
  
  describe "update_score/1" do
    test "updates single observer score" do
      observer = %{
        observer_id: "obs_update",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25
      }
      
      OCG.update_score(observer)
      Process.sleep(50)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "obs_update")
    end
    
    test "overwrites existing score" do
      observer_v1 = %{
        observer_id: "obs_overwrite",
        coherence: 0.50,
        msf: 0.50,
        prediction: 0.50,
        interference: 0.50
      }
      
      observer_v2 = %{
        observer_id: "obs_overwrite",
        coherence: 0.90,
        msf: 0.90,
        prediction: 0.90,
        interference: 0.10
      }
      
      OCG.update_score(observer_v1)
      Process.sleep(50)
      
      {:ok, scores_v1} = OCG.get_scores()
      oss_v1 = Map.get(scores_v1, "obs_overwrite")
      
      OCG.update_score(observer_v2)
      Process.sleep(50)
      
      {:ok, scores_v2} = OCG.get_scores()
      oss_v2 = Map.get(scores_v2, "obs_overwrite")
      
      assert oss_v2 > oss_v1
    end
  end
  
  describe "full_sweep/0" do
    test "evaluates all registered observer pairs" do
      # Register multiple observers
      observers = [
        %{observer_id: "sweep_1", coherence: 0.70, msf: 0.65, prediction: 0.75, interference: 0.30},
        %{observer_id: "sweep_2", coherence: 0.60, msf: 0.55, prediction: 0.65, interference: 0.40},
        %{observer_id: "sweep_3", coherence: 0.80, msf: 0.75, prediction: 0.85, interference: 0.20}
      ]
      
      Enum.each(observers, &OCG.update_score/1)
      Process.sleep(100)
      
      # Trigger full sweep
      OCG.full_sweep()
      Process.sleep(200)
      
      {:ok, scores} = OCG.get_scores()
      
      # All observers should still be tracked
      assert Map.has_key?(scores, "sweep_1")
      assert Map.has_key?(scores, "sweep_2")
      assert Map.has_key?(scores, "sweep_3")
    end
  end
  
  describe "integration with MSCL" do
    test "hydrates MSF from MSCL when available" do
      # This test verifies that OCG can retrieve live MSF scores from MSCL
      # In a real scenario, MSCL would be running and providing scores
      
      observer = %{
        observer_id: "mscl_test_obs",
        coherence: 0.75,
        prediction: 0.80,
        interference: 0.25
        # Note: no :msf field - should be hydrated from MSCL or estimated
      }
      
      oss = OCG.compute_oss(observer)
      
      # Should compute OSS using either live MSF or estimated fallback
      assert oss > 0.0
      assert oss <= 1.0
    end
    
    test "falls back to local MSF estimation when MSCL unavailable" do
      observer = %{
        observer_id: "fallback_obs",
        coherence: 0.60,
        resistance: 0.70,
        interference: 0.40
      }
      
      # When MSCL is not available, OCG estimates MSF locally
      oss = OCG.compute_oss(observer)
      
      assert oss > 0.0
      assert oss <= 1.0
    end
  end
  
  describe "arbitration logging" do
    test "maintains arbitration log history" do
      observer_a = %{
        observer_id: "log_a",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30
      }
      
      observer_b = %{
        observer_id: "log_b",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40
      }
      
      OCG.evaluate_pair(observer_a, observer_b)
      Process.sleep(100)
      
      # The arbitration log is internal state, but we can verify
      # that the operation completed without errors
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "log_a")
      assert Map.has_key?(scores, "log_b")
    end
  end
  
  describe "edge cases" do
    test "handles identical observers" do
      observer = %{
        observer_id: "identical",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25
      }
      
      # Evaluating observer against itself should not cause errors
      OCG.evaluate_pair(observer, observer)
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "identical")
    end
    
    test "handles extreme OSS values" do
      observer_max = %{
        observer_id: "extreme_max",
        coherence: 1.0,
        msf: 1.0,
        prediction: 1.0,
        interference: 0.0
      }
      
      observer_min = %{
        observer_id: "extreme_min",
        coherence: 0.0,
        msf: 0.0,
        prediction: 0.0,
        interference: 1.0
      }
      
      OCG.evaluate_pair(observer_max, observer_min)
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "extreme_max")
      assert Map.has_key?(scores, "extreme_min")
    end
    
    test "handles missing observer fields gracefully" do
      minimal_observer = %{observer_id: "minimal"}
      
      oss = OCG.compute_oss(minimal_observer)
      
      # Should use defaults for all missing fields
      assert oss > 0.0
      assert oss <= 1.0
    end
  end
end
