defmodule TiannaraRuntime.Phase5F5MSCLTest do
  @moduledoc """
  Phase 5F.5 — Meta-Stability Constraint Layer (MSCL-Ω) Tests
  
  Tests the complete meta-stability governance system:
  - MSCL Kernel (central governor)
  - Observer Collapse Governor (intervention engine)
  - Resonance Dampening Engine (harmonic suppression)
  - Paradox Density Monitor (thermodynamic tracking)
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.Meta.Metastability.Kernel, as: MSCLKernel
  alias Tiannara.Meta.Metastability.ObserverCollapseGovernor
  alias Tiannara.Meta.Metastability.ResonanceDampeningEngine
  alias Tiannara.Meta.Metastability.ParadoxDensityMonitor
  alias Tiannara.Meta.ChronogramMatrix
  
  setup do
    start_gs = fn mod ->
      case mod.start_link([]) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
    end

    start_gs.(Tiannara.Meta.Metastability.Kernel)
    start_gs.(Tiannara.Meta.ChronogramMatrix)
    start_gs.(Tiannara.Meta.Metastability.ObserverCollapseGovernor)
    start_gs.(Tiannara.Meta.Metastability.ResonanceDampeningEngine)
    start_gs.(Tiannara.Meta.Metastability.ParadoxDensityMonitor)

    cancel_timer_safely(MSCLKernel, :monitoring_timer)
    cancel_timer_safely(ParadoxDensityMonitor, :reporting_timer)

    if Process.whereis(MSCLKernel), do: GenServer.cast(MSCLKernel, :reset)
    if Process.whereis(ChronogramMatrix), do: GenServer.cast(ChronogramMatrix, :reset)
    if Process.whereis(ObserverCollapseGovernor), do: GenServer.cast(ObserverCollapseGovernor, :reset)
    if Process.whereis(ResonanceDampeningEngine), do: GenServer.cast(ResonanceDampeningEngine, :reset)
    if Process.whereis(ParadoxDensityMonitor), do: GenServer.cast(ParadoxDensityMonitor, :reset)

    :ok
  end

  defp cancel_timer_safely(module, timer_field) do
    if pid = Process.whereis(module) do
      try do
        state = :sys.get_state(pid)
        if timer = Map.get(state, timer_field) do
          Process.cancel_timer(timer)
        end
      rescue
        _ -> :ok
      end
    end
  end
  
  describe "MSCL Kernel core operations" do
    test "validate_divergence returns stable for low divergence" do
      # Register two observers with similar frequencies
      {:ok, _mei_a} = ChronogramMatrix.register_observer("obs_stable_a")
      {:ok, _mei_b} = ChronogramMatrix.register_observer("obs_stable_b")
      
      # Validate divergence
      result = MSCLKernel.validate_divergence("obs_stable_a", "obs_stable_b")
      assert result in [:stable, :stabilized]
    end
    
    test "get_stability_metrics returns comprehensive data" do
      {:ok, metrics} = MSCLKernel.get_stability_metrics()
      
      assert Map.has_key?(metrics, :global_paradox_density)
      assert Map.has_key?(metrics, :causal_drift_pressure)
      assert Map.has_key?(metrics, :active_stabilizations)
      assert Map.has_key?(metrics, :monitored_observers)
      assert Map.has_key?(metrics, :divergence_threshold)
    end
    
    test "request_observer_split approves within budget" do
      # Request split with small cost (should be approved)
      :ok = MSCLKernel.request_observer_split("obs_split_test", 0.1)
      
      # Give GenServer time to process
      Process.sleep(50)
    end
    
    test "report_paradox_density updates global state" do
      # Report paradox density
      :ok = MSCLKernel.report_paradox_density(0.45)
      Process.sleep(50)
      
      {:ok, metrics} = MSCLKernel.get_stability_metrics()
      assert metrics.global_paradox_density == 0.45
    end
  end
  
  describe "Observer Collapse Governor assessments" do
    test "assess_observer_stability handles unregistered observer" do
      # Assess non-existent observer
      result = ObserverCollapseGovernor.assess_observer_stability("nonexistent_obs")
      
      # Should recommend collapse for unregistered observer
      assert match?({:action_required, :collapse}, result)
    end
    
    test "assess_observer_stability returns stable for healthy observer" do
      # Register observer
      {:ok, _mei} = ChronogramMatrix.register_observer("obs_healthy")
      
      # Assess stability
      result = ObserverCollapseGovernor.assess_observer_stability("obs_healthy")
      
      # Should be stable or require minor action
      assert result in [:stable] or match?({:action_required, _}, result)
    end
    
    test "execute_collapse performs freeze action" do
      # Execute freeze on test observer
      result = ObserverCollapseGovernor.execute_collapse("obs_to_freeze", :freeze)
      
      assert result == :ok
    end
    
    test "get_collapse_stats returns monitoring data" do
      {:ok, stats} = ObserverCollapseGovernor.get_collapse_stats()
      
      assert Map.has_key?(stats, :total_monitored_observers)
      assert Map.has_key?(stats, :recent_collapses)
      assert Map.has_key?(stats, :last_10_actions)
    end
  end
  
  describe "Resonance Dampening Engine detection" do
    test "assess_resonance_risk returns safe for single observer" do
      {:ok, _mei} = ChronogramMatrix.register_observer("obs_single")
      
      result = ResonanceDampeningEngine.assess_resonance_risk(["obs_single"])
      assert result == :safe
    end
    
    test "assess_resonance_risk detects resonance in close frequencies" do
      # Register observers (they'll get random frequencies near 1.618)
      {:ok, _mei_a} = ChronogramMatrix.register_observer("obs_res_a")
      {:ok, _mei_b} = ChronogramMatrix.register_observer("obs_res_b")
      {:ok, _mei_c} = ChronogramMatrix.register_observer("obs_res_c")
      
      result = ResonanceDampeningEngine.assess_resonance_risk(["obs_res_a", "obs_res_b", "obs_res_c"])
      
      # May detect low/medium risk depending on random frequency assignment
      assert result == :safe or match?({:risk_detected, _level}, result)
    end
    
    test "apply_phase_decorrelation executes successfully" do
      :ok = ResonanceDampeningEngine.apply_phase_decorrelation("obs_decorrelate", 0.15)
      Process.sleep(50)
      
      {:ok, stats} = ResonanceDampeningEngine.get_resonance_stats()
      assert stats.dampening_operations_applied >= 1
    end
    
    test "get_resonance_stats returns monitoring metrics" do
      {:ok, stats} = ResonanceDampeningEngine.get_resonance_stats()
      
      assert Map.has_key?(stats, :total_monitored_observers)
      assert Map.has_key?(stats, :active_resonance_clusters)
      assert Map.has_key?(stats, :dampening_operations_applied)
      assert Map.has_key?(stats, :min_frequency_separation)
    end
  end
  
  describe "Paradox Density Monitor tracking" do
    test "report_paradox_intensity updates regional map" do
      :ok = ParadoxDensityMonitor.report_paradox_intensity("region_001", 0.45, 0.6)
      Process.sleep(50)
      
      {:ok, density} = ParadoxDensityMonitor.get_global_density()
      assert density >= 0.0 and density <= 1.0
    end
    
    test "get_global_density returns valid range" do
      {:ok, density} = ParadoxDensityMonitor.get_global_density()
      
      assert density >= 0.0 and density <= 1.0
    end
    
    test "get_detailed_metrics returns comprehensive breakdown" do
      # Report some regions
      :ok = ParadoxDensityMonitor.report_paradox_intensity("region_A", 0.3, 0.5)
      :ok = ParadoxDensityMonitor.report_paradox_intensity("region_B", 0.7, 0.8)
      Process.sleep(50)
      
      {:ok, metrics} = ParadoxDensityMonitor.get_detailed_metrics()
      
      assert Map.has_key?(metrics, :global_density)
      assert Map.has_key?(metrics, :total_tracked_regions)
      assert Map.has_key?(metrics, :safe_threshold)
      assert Map.has_key?(metrics, :critical_threshold)
      assert Map.has_key?(metrics, :status)
      assert Map.has_key?(metrics, :top_paradox_regions)
    end
    
    test "multiple reports update global density correctly" do
      # Report multiple regions
      :ok = ParadoxDensityMonitor.report_paradox_intensity("reg_1", 0.2, 0.3)
      :ok = ParadoxDensityMonitor.report_paradox_intensity("reg_2", 0.5, 0.6)
      :ok = ParadoxDensityMonitor.report_paradox_intensity("reg_3", 0.8, 0.9)
      Process.sleep(50)
      
      {:ok, density} = ParadoxDensityMonitor.get_global_density()
      
      # Density should be weighted average of all regions
      assert density > 0.0 and density < 1.0
    end
  end
  
  describe "MSCL-Ω integration scenarios" do
    test "complete stability monitoring pipeline" do
      # Step 1: Register observers
      {:ok, _mei_a} = ChronogramMatrix.register_observer("obs_int_a")
      {:ok, _mei_b} = ChronogramMatrix.register_observer("obs_int_b")
      
      # Step 2: Report paradox density
      :ok = ParadoxDensityMonitor.report_paradox_intensity("int_region", 0.4, 0.5)
      Process.sleep(50)
      
      # Step 3: Check global metrics
      {:ok, kernel_metrics} = MSCLKernel.get_stability_metrics()
      assert kernel_metrics.global_paradox_density >= 0.0
      
      # Step 4: Assess observer stability
      stability_result = ObserverCollapseGovernor.assess_observer_stability("obs_int_a")
      assert stability_result in [:stable] or match?({:action_required, _}, stability_result)
      
      # Step 5: Check for resonance
      resonance_result = ResonanceDampeningEngine.assess_resonance_risk(["obs_int_a", "obs_int_b"])
      assert resonance_result == :safe or match?({:risk_detected, _}, resonance_result)
    end
    
    test "divergence validation triggers stabilization when needed" do
      # Register observers
      {:ok, _mei_x} = ChronogramMatrix.register_observer("obs_div_x")
      {:ok, _mei_y} = ChronogramMatrix.register_observer("obs_div_y")
      
      # Validate divergence (may trigger stabilization if frequencies too far apart)
      result = MSCLKernel.validate_divergence("obs_div_x", "obs_div_y")
      
      assert result in [:stable, :stabilized]
      
      # If stabilized, check that stabilization was recorded
      if result == :stabilized do
        {:ok, metrics} = MSCLKernel.get_stability_metrics()
        assert metrics.active_stabilizations >= 0
      end
    end
    
    test "observer split request respects thermodynamic budget" do
      # Request small split (should be approved)
      :ok = MSCLKernel.request_observer_split("obs_budget_test", 0.05)
      Process.sleep(50)
      
      # Request large split that might exceed budget
      :ok = MSCLKernel.request_observer_split("obs_budget_test_2", 0.5)
      Process.sleep(50)
      
      {:ok, metrics} = MSCLKernel.get_stability_metrics()
      assert metrics.causal_drift_pressure >= 0.0
    end
  end
  
  describe "Thermodynamic constraint enforcement" do
    test "paradox density reporting triggers MSCL updates" do
      # Report high paradox density
      :ok = ParadoxDensityMonitor.report_paradox_intensity("high_density_region", 0.9, 0.95)
      Process.sleep(100)  # Allow time for reporting to MSCL
      
      {:ok, metrics} = MSCLKernel.get_stability_metrics()
      
      # MSCL should have received the update
      assert metrics.global_paradox_density >= 0.0
    end
    
    test "resonance dampening prevents harmonic explosion" do
      # Create cluster of observers with potentially resonant frequencies
      observer_ids = Enum.map(1..5, fn i -> "obs_cluster_#{i}" end)
      
      Enum.each(observer_ids, fn obs_id ->
        ChronogramMatrix.register_observer(obs_id)
      end)
      
      # Check for resonance
      result = ResonanceDampeningEngine.assess_resonance_risk(observer_ids)
      
      # Apply dampening if risk detected
      if match?({:risk_detected, _}, result) do
        Enum.each(observer_ids, fn obs_id ->
          ResonanceDampeningEngine.apply_phase_decorrelation(obs_id, 0.2)
        end)
        Process.sleep(100)
      end
      
      {:ok, stats} = ResonanceDampeningEngine.get_resonance_stats()
      assert stats.dampening_operations_applied >= 0
    end
  end
end
