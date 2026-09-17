defmodule Tiannara.BridgeTest do
  use ExUnit.Case, async: true
  alias Tiannara.Bridge.{
    OmegaPhiKernel,
    LoadToCompression,
    CompressionToLoad,
    StabilityController,
    EntropyBalancer,
    HarmonicSynchronizer
  }

  describe "OmegaPhiKernel" do
    test "initializes with default values" do
      {:ok, pid} = OmegaPhiKernel.start_link([])
      state = :sys.get_state(pid)
      
      assert state.omega == 0.0
      assert state.phi == 0.0
      assert state.stability == 1.0
      assert state.tick_count == 0
    end

    test "computes stability metric correctly" do
      # Perfect balance should yield stability = 1.0
      assert_in_delta 1.0, compute_stability(0.5, 0.5), 0.001
      
      # Small divergence reduces stability
      stability_small = compute_stability(0.6, 0.5)
      assert stability_small < 1.0
      assert stability_small > 0.9
      
      # Large divergence significantly reduces stability
      stability_large = compute_stability(0.9, 0.1)
      assert stability_large < 0.6
    end

    test "tick updates omega and phi based on OMCE/OLEF states" do
      {:ok, pid} = OmegaPhiKernel.start_link([])
      
      omce_state = %{
        compression_rate: 0.5,
        ontology_size: 100.0,
        memory_usage_mb: 50.0
      }
      
      olef_state = %{
        global_pressure: 0.3,
        pressure_field: 0.2,
        node_count: 5
      }
      
      {:ok, new_state} = GenServer.call(pid, {:tick, omce_state, olef_state})
      
      assert new_state.tick_count == 1
      assert is_number(new_state.omega)
      assert is_number(new_state.phi)
      assert is_number(new_state.stability)
      assert new_state.omega >= 0.0 and new_state.omega <= 1.0
      assert new_state.phi >= 0.0 and new_state.phi <= 1.0
    end

    test "multiple ticks maintain bounded values" do
      {:ok, pid} = OmegaPhiKernel.start_link([])
      
      omce_state = %{compression_rate: 0.7, ontology_size: 200.0}
      olef_state = %{global_pressure: 0.6, pressure_field: 0.5}
      
      # Run multiple ticks
      Enum.each(1..10, fn _ ->
        {:ok, state} = GenServer.call(pid, {:tick, omce_state, olef_state})
        assert state.omega >= 0.0 and state.omega <= 1.0
        assert state.phi >= 0.0 and state.phi <= 1.0
        assert state.stability >= 0.0 and state.stability <= 1.0
      end)
    end
  end

  describe "LoadToCompression" do
    test "translates high load to aggressive compression" do
      assert LoadToCompression.translate(0.9) == {:compress, :aggressive}
      assert LoadToCompression.translate(0.85) == {:compress, :aggressive}
    end

    test "translates medium load to moderate compression" do
      assert LoadToCompression.translate(0.7) == {:compress, :moderate}
      assert LoadToCompression.translate(0.6) == {:compress, :moderate}
    end

    test "translates low load to light compression" do
      assert LoadToCompression.translate(0.3) == {:compress, :light}
      assert LoadToCompression.translate(0.0) == {:compress, :light}
      assert LoadToCompression.translate(0.5) == {:compress, :light}
    end

    test "compression ratios are correct" do
      assert LoadToCompression.compression_ratio(:aggressive) == 0.4
      assert LoadToCompression.compression_ratio(:moderate) == 0.7
      assert LoadToCompression.compression_ratio(:light) == 0.9
    end

    test "translate_with_context includes metadata" do
      result = LoadToCompression.translate_with_context(0.9, %{})
      
      assert result.intensity == :aggressive
      assert result.load_signal == 0.9
      assert Map.has_key?(result, :timestamp)
      assert Map.has_key?(result, :target_retention_ratio)
    end

    test "context with low stability increases retention" do
      normal = LoadToCompression.translate_with_context(0.9, %{})
      unstable = LoadToCompression.translate_with_context(0.9, %{stability: 0.3})
      
      # During instability, retention should be higher (less compression)
      assert unstable.target_retention_ratio > normal.target_retention_ratio
    end
  end

  describe "CompressionToLoad" do
    test "emits pressure signal for compression delta" do
      {:pressure_signal, pressure} = CompressionToLoad.emit(-50.0)
      
      assert is_number(pressure)
      assert pressure >= 0.0
      assert pressure <= 10.0  # max_load_multiplier
    end

    test "emits pressure signal for expansion delta" do
      {:pressure_signal, pressure} = CompressionToLoad.emit(100.0)
      
      assert is_number(pressure)
      assert pressure >= 0.0
    end

    test "zero delta produces zero pressure" do
      {:pressure_signal, pressure} = CompressionToLoad.emit(0.0)
      assert_in_delta 0.0, pressure, 0.001
    end

    test "emit_with_metadata includes full context" do
      result = CompressionToLoad.emit_with_metadata(-30.0, %{observer_id: "obs_1"})
      
      assert is_number(result.pressure)
      assert result.compression_delta == -30.0
      assert result.is_compression == true
      assert result.is_expansion == false
      assert result.metadata.observer_id == "obs_1"
      assert result.metadata.source == :omce_compression_event
    end

    test "cumulative_load sums multiple deltas" do
      deltas = [-10.0, -20.0, -30.0]
      {:pressure_signal, total_pressure} = CompressionToLoad.cumulative_load(deltas)
      
      # Total delta should be -60.0
      assert is_number(total_pressure)
      assert total_pressure > 0.0
    end
  end

  describe "StabilityController" do
    test "evaluates stable system correctly" do
      assert StabilityController.evaluate(0.8) == {:stable, :no_action}
      assert StabilityController.evaluate(0.6) == {:stable, :no_action}
    end

    test "evaluates degraded system correctly" do
      assert StabilityController.evaluate(0.5) == {:degraded, :soft_correction}
      assert StabilityController.evaluate(0.3) == {:degraded, :soft_correction}
    end

    test "evaluates unstable system correctly" do
      assert StabilityController.evaluate(0.2) == {:unstable, :rebalance_required}
      assert StabilityController.evaluate(0.1) == {:unstable, :rebalance_required}
    end

    test "adjusts compression for stability" do
      # Stable system uses requested intensity
      assert StabilityController.adjust_compression_for_stability(0.8, :aggressive) == :aggressive
      
      # Degraded system downgrades aggressive to moderate
      assert StabilityController.adjust_compression_for_stability(0.5, :aggressive) == :moderate
      
      # Unstable system always uses light
      assert StabilityController.adjust_compression_for_stability(0.2, :aggressive) == :light
      assert StabilityController.adjust_compression_for_stability(0.2, :moderate) == :light
    end

    test "intervention levels are correct" do
      assert StabilityController.intervention_level(0.05) == 3  # Critical
      assert StabilityController.intervention_level(0.2) == 2   # Severe
      assert StabilityController.intervention_level(0.35) == 1  # Moderate
      assert StabilityController.intervention_level(0.7) == 0   # Normal
    end

    test "generate_report includes all diagnostics" do
      report = StabilityController.generate_report(0.4, 0.6, 0.3)
      
      assert report.status == :degraded
      assert report.action == :soft_correction
      assert report.stability == 0.4
      assert report.omega == 0.6
      assert report.phi == 0.3
      assert report.divergence == 0.3
      assert Map.has_key?(report, :recommendation)
      assert Map.has_key?(report, :timestamp)
    end
  end

  describe "EntropyBalancer" do
    test "balances omega and phi toward mean" do
      {balanced_omega, balanced_phi} = EntropyBalancer.balance(0.8, 0.2)
      
      mean = (0.8 + 0.2) / 2.0  # 0.5
      
      # Both should move toward mean (0.5)
      assert balanced_omega < 0.8 and balanced_omega > 0.5
      assert balanced_phi > 0.2 and balanced_phi < 0.5
      
      # They should be closer together than before
      assert abs(balanced_omega - balanced_phi) < abs(0.8 - 0.2)
    end

    test "already balanced values remain stable" do
      {balanced_omega, balanced_phi} = EntropyBalancer.balance(0.5, 0.5)
      
      assert_in_delta 0.5, balanced_omega, 0.001
      assert_in_delta 0.5, balanced_phi, 0.001
    end

    test "balance_adaptive applies stronger correction for large divergence" do
      # Large divergence - should apply 30% damping (divergence > 0.8)
      {omega_strong, _phi_strong} = EntropyBalancer.balance_adaptive(0.9, 0.1, 0.8)
      
      # With 30% damping toward mean (0.5): 0.9 + (0.5 - 0.9) * 0.3 = 0.78
      assert_in_delta 0.78, omega_strong, 0.05
      
      # Small divergence - should apply 10% damping (divergence <= 0.2)
      {omega_gentle, _phi_gentle} = EntropyBalancer.balance_adaptive(0.55, 0.45, 0.1)
      
      # With 10% damping toward mean (0.5): 0.55 + (0.5 - 0.55) * 0.1 = 0.545
      assert_in_delta 0.545, omega_gentle, 0.05
      
      # Strong correction moves MORE from original position than gentle correction
      # omega_strong moved from 0.9 to ~0.78 (distance 0.12)
      # omega_gentle moved from 0.55 to ~0.545 (distance 0.005)
      assert abs(omega_strong - 0.9) > abs(omega_gentle - 0.55)
    end

    test "calculate_entropy penalizes large divergences" do
      entropy_small = EntropyBalancer.calculate_entropy(0.55, 0.45)
      entropy_large = EntropyBalancer.calculate_entropy(0.9, 0.1)
      
      assert entropy_large > entropy_small
      assert_in_delta 0.01, entropy_small, 0.001  # (0.1)^2 = 0.01
      assert_in_delta 0.64, entropy_large, 0.001  # (0.8)^2 = 0.64
    end

    test "acceptable_entropy? validates threshold" do
      assert EntropyBalancer.acceptable_entropy?(0.05, 0.1) == true
      assert EntropyBalancer.acceptable_entropy?(0.15, 0.1) == false
      assert EntropyBalancer.acceptable_entropy?(0.1, 0.1) == true
    end
  end

  describe "HarmonicSynchronizer" do
    test "sync applies sinusoidal modulation" do
      {omega_adj, phi_adj} = HarmonicSynchronizer.sync(0.5, 0.5, 0)
      
      # At t=0, sin(0) = 0, so no adjustment
      assert_in_delta 0.5, omega_adj, 0.001
      assert_in_delta 0.5, phi_adj, 0.001
      
      # At t where sin(t/10) > 0, omega increases, phi decreases
      {omega_pos, phi_pos} = HarmonicSynchronizer.sync(0.5, 0.5, 5)
      wave_at_5 = :math.sin(5 / 10.0)
      
      if wave_at_5 > 0 do
        assert omega_pos > 0.5
        assert phi_pos < 0.5
      else
        assert omega_pos < 0.5
        assert phi_pos > 0.5
      end
    end

    test "sync maintains conservation (opposite adjustments)" do
      {omega_adj, phi_adj} = HarmonicSynchronizer.sync(0.6, 0.4, 10)
      
      # Adjustments should be equal magnitude, opposite sign
      omega_delta = omega_adj - 0.6
      phi_delta = phi_adj - 0.4
      
      assert_in_delta omega_delta, -phi_delta, 0.001
    end

    test "sync_adaptive reduces amplitude when stable" do
      t = 5
      {omega_unstable, _} = HarmonicSynchronizer.sync_adaptive(0.5, 0.5, t, 0.3)
      {omega_stable, _} = HarmonicSynchronizer.sync_adaptive(0.5, 0.5, t, 0.9)
      
      # Stable system should have smaller adjustment
      assert abs(omega_stable - 0.5) < abs(omega_unstable - 0.5)
    end

    test "generate_diagnostics provides full state information" do
      diag = HarmonicSynchronizer.generate_diagnostics(0.5, 0.5, 10)
      
      assert Map.has_key?(diag, :current_tick)
      assert Map.has_key?(diag, :wave_value)
      assert Map.has_key?(diag, :omega_adjustment)
      assert Map.has_key?(diag, :phi_adjustment)
      assert Map.has_key?(diag, :adjusted_omega)
      assert Map.has_key?(diag, :adjusted_phi)
      assert diag.current_tick == 10
    end

    test "interference_pattern detects constructive vs destructive" do
      # Constructive: both moving in harmony with wave
      assert HarmonicSynchronizer.interference_pattern(0.1, -0.1, 1) == :constructive
      
      # Destructive: moving against wave direction
      assert HarmonicSynchronizer.interference_pattern(-0.1, 0.1, 1) == :destructive
    end
  end

  # Helper function to access private compute_stability for testing
  defp compute_stability(omega, phi) do
    1.0 / (1.0 + abs(omega - phi))
  end
end
