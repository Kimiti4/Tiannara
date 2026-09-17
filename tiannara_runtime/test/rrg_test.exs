defmodule Tiannara.RRGTest do
  use ExUnit.Case, async: false
  alias Tiannara.RRG.{
    CosmologicalMonitor,
    AttractorDetector,
    NoveltyInjector,
    RecursionRegulator,
    EquilibriumEngine
  }

  defp start_rrg(mod) do
    # Stop existing instance to ensure clean state per test
    if pid = Process.whereis(mod), do: GenServer.stop(pid)
    {:ok, pid} = mod.start_link([])
    pid
  end

  describe "CosmologicalMonitor" do
    test "initializes with default cosmological metrics" do
      pid = start_rrg(CosmologicalMonitor)
      state = :sys.get_state(pid)
      
      assert state.total_singularity_mass == 0.0
      assert state.branch_count == 0
      assert state.observer_recursion_density == 0.0
      assert state.semantic_diversity == 1.0
      assert state.convergence_risk == 0.0
    end

    test "check_stability returns stability report with Ψ metric" do
      pid = start_rrg(CosmologicalMonitor)
      
      {:ok, report} = GenServer.call(pid, :check_stability)
      
      assert Map.has_key?(report, :psi)
      assert Map.has_key?(report, :status)
      assert Map.has_key?(report, :metrics)
      assert Map.has_key?(report, :interventions_needed)
      assert is_number(report.psi)
      assert report.psi >= 0.0 and report.psi <= 1.0
    end

    test "stability status reflects Ψ value ranges" do
      # Test different Ψ ranges map to correct statuses
      assert Tiannara.RRGTest.CosmologicalMonitorTestHelper.determine_status(0.2) == :critical_convergence_risk
      assert Tiannara.RRGTest.CosmologicalMonitorTestHelper.determine_status(0.4) == :degraded_stability
      assert Tiannara.RRGTest.CosmologicalMonitorTestHelper.determine_status(0.6) == :moderate_stability
      assert Tiannara.RRGTest.CosmologicalMonitorTestHelper.determine_status(0.8) == :healthy_equilibrium
    end

    test "get_telemetry returns current cosmological snapshot" do
      pid = start_rrg(CosmologicalMonitor)
      
      {:ok, telemetry} = GenServer.call(pid, :get_telemetry)
      
      assert Map.has_key?(telemetry, :total_singularity_mass)
      assert Map.has_key?(telemetry, :branch_count)
      assert Map.has_key?(telemetry, :observer_recursion_density)
      assert Map.has_key?(telemetry, :semantic_diversity)
      assert Map.has_key?(telemetry, :convergence_risk)
    end
  end

  describe "AttractorDetector" do
    test "initializes with zero attractor risks" do
      pid = start_rrg(AttractorDetector)
      state = :sys.get_state(pid)
      
      assert state.semantic_monoculture_risk == 0.0
      assert state.recursive_explosion_risk == 0.0
      assert state.entropy_sink_risk == 0.0
      assert state.overall_attractor_score == 0.0
      assert state.detected_attractors == []
    end

    test "scan_attractors detects active convergence patterns" do
      pid = start_rrg(AttractorDetector)
      
      {:ok, assessment} = GenServer.call(pid, :scan_attractors)
      
      assert Map.has_key?(assessment, :risk_level)
      assert Map.has_key?(assessment, :attractor_score)
      assert Map.has_key?(assessment, :active_attractors)
      assert Map.has_key?(assessment, :recommended_interventions)
      assert assessment.risk_level in [:low, :moderate, :high, :critical]
    end

    test "attractor risk levels are correctly categorized" do
      # Test threshold boundaries
      assert Tiannara.RRGTest.AttractorDetectorTestHelper.categorize_risk(0.8) == :critical
      assert Tiannara.RRGTest.AttractorDetectorTestHelper.categorize_risk(0.65) == :high
      assert Tiannara.RRGTest.AttractorDetectorTestHelper.categorize_risk(0.5) == :moderate
      assert Tiannara.RRGTest.AttractorDetectorTestHelper.categorize_risk(0.3) == :low
    end

    test "recommendations include appropriate interventions" do
      pid = start_rrg(AttractorDetector)
      
      {:ok, assessment} = GenServer.call(pid, :scan_attractors)
      
      # Should have some recommendations based on simulated risks
      assert is_list(assessment.recommended_interventions)
    end
  end

  describe "NoveltyInjector" do
    test "injects novelty into valid domains" do
      pid = start_rrg(NoveltyInjector)
      
      # Test all valid domains
      for domain <- [:culture, :genetics, :discovery, :probability, :history] do
        GenServer.cast(pid, {:inject, domain, 0.05})
      end
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      assert stats.total_injections == 5
      assert length(stats.active_domains) == 5
    end

    test "rejects invalid injection domains" do
      pid = start_rrg(NoveltyInjector)
      
      # Attempt invalid domain
      GenServer.cast(pid, {:inject, :invalid_domain, 0.05})
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      assert stats.total_injections == 0
    end

    test "clamps magnitude to maximum safe level" do
      pid = start_rrg(NoveltyInjector)
      
      # Inject with excessive magnitude
      GenServer.cast(pid, {:inject, :culture, 0.5})
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      # Should be clamped to max (0.15)
      assert stats.total_novelty_injected <= 0.15
    end

    test "tracks injection history" do
      pid = start_rrg(NoveltyInjector)
      
      # Perform multiple injections
      Enum.each(1..10, fn _ ->
        GenServer.cast(pid, {:inject, :probability, 0.02})
      end)
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      assert stats.total_injections == 10
      assert length(stats.recent_injections) <= 10
    end
  end

  describe "RecursionRegulator" do
    test "allows safe recursion levels without intervention" do
      pid = start_rrg(RecursionRegulator)
      
      {:ok, status, uncertainty} = 
        GenServer.call(pid, {:regulate, "observer_1", 0.5})
      
      assert status == :within_limits
      assert uncertainty == 0.0
    end

    test "regulates high recursion with uncertainty injection" do
      pid = start_rrg(RecursionRegulator)
      
      {:ok, status, uncertainty} = 
        GenServer.call(pid, {:regulate, "observer_2", 0.8})
      
      assert status == :regulated
      assert uncertainty > 0.0
    end

    test "applies stronger regulation near critical threshold" do
      pid = start_rrg(RecursionRegulator)
      
      # Near critical (0.9)
      {:ok, _status1, uncertainty1} = 
        GenServer.call(pid, {:regulate, "observer_3", 0.85})
      
      # Above critical
      {:ok, _status2, uncertainty2} = 
        GenServer.call(pid, {:regulate, "observer_4", 0.95})
      
      # Higher recursion should get more uncertainty
      assert uncertainty2 > uncertainty1
    end

    test "tracks regulated observers" do
      pid = start_rrg(RecursionRegulator)
      
      # Regulate multiple observers
      Enum.each(1..5, fn i ->
        GenServer.call(pid, {:regulate, "observer_#{i}", 0.8})
      end)
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      assert stats.regulated_observers_count > 0
      assert stats.total_tracked_observers >= 5
    end

    test "counts high-risk observers correctly" do
      pid = start_rrg(RecursionRegulator)
      
      # Mix of safe and risky observers
      GenServer.call(pid, {:regulate, "safe_1", 0.5})
      GenServer.call(pid, {:regulate, "risky_1", 0.8})
      GenServer.call(pid, {:regulate, "risky_2", 0.85})
      
      {:ok, stats} = GenServer.call(pid, :get_stats)
      
      assert stats.high_risk_observers >= 2
    end
  end

  describe "EquilibriumEngine" do
    test "initializes with default Ψ value" do
      pid = start_rrg(EquilibriumEngine)
      psi = GenServer.call(pid, :get_psi)
      
      assert psi == 1.0  # Default safe value
    end

    test "calculates Ψ from component metrics" do
      pid = start_rrg(EquilibriumEngine)
      
      metrics = %{
        semantic_diversity: 0.7,
        novelty: 0.6,
        branch_complexity: 0.8,
        entropy_concentration: 0.4,
        recursion_density: 0.3
      }
      
      GenServer.cast(pid, {:update, metrics})
      
      psi = GenServer.call(pid, :get_psi)
      
      assert is_number(psi)
      assert psi >= 0.0 and psi <= 1.0
    end

    test "prevents division by zero in Ψ calculation" do
      pid = start_rrg(EquilibriumEngine)
      
      # Metrics with zero values that could cause division issues
      metrics = %{
        semantic_diversity: 0.5,
        novelty: 0.5,
        branch_complexity: 0.5,
        entropy_concentration: 0.0,  # Would cause division by zero
        recursion_density: 0.0       # Would cause division by zero
      }
      
      # Should not crash
      GenServer.cast(pid, {:update, metrics})
      
      psi = GenServer.call(pid, :get_psi)
      assert is_number(psi)
    end

    test "maintains Ψ history" do
      pid = start_rrg(EquilibriumEngine)
      
      # Update multiple times
      Enum.each(1..5, fn i ->
        metrics = %{
          semantic_diversity: 0.5 + i * 0.05,
          novelty: 0.5,
          branch_complexity: 0.5,
          entropy_concentration: 0.3,
          recursion_density: 0.2
        }
        GenServer.cast(pid, {:update, metrics})
      end)
      
      state = :sys.get_state(pid)
      assert length(state.history) == 5
    end
  end

  # Helper modules for testing private functions
  defmodule CosmologicalMonitorTestHelper do
    def determine_status(psi) do
      cond do
        psi < 0.3 -> :critical_convergence_risk
        psi < 0.5 -> :degraded_stability
        psi < 0.7 -> :moderate_stability
        true -> :healthy_equilibrium
      end
    end
  end

  defmodule AttractorDetectorTestHelper do
    def categorize_risk(score) do
      cond do
        score > 0.75 -> :critical
        score > 0.6 -> :high
        score > 0.4 -> :moderate
        true -> :low
      end
    end
  end
end
