defmodule Tiannara.Physics.SubsystemQuarantineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Physics.{NDE, OPC, IRD, TWP}

  test "NDE client surface is quarantined" do
    assert {:error, :physics_substrate_unavailable} = NDE.differentiate_chaotic_state(%{})
    assert {:error, :physics_substrate_unavailable} = NDE.create_negentropic_pattern(:p1, [])
    assert {:error, :physics_substrate_unavailable} = NDE.get_negentropic_patterns()
    assert {:error, :physics_substrate_unavailable} = NDE.calculate_negentropy_level(:p1)
    assert {:error, :physics_substrate_unavailable} = NDE.optimize_negentropic_structure(:p1)
    assert {:error, :physics_substrate_unavailable} = NDE.get_negentropy_metrics()
    assert {:error, :physics_substrate_unavailable} = NDE.validate_negentropic_integrity()
    assert {:error, :physics_substrate_unavailable} = NDE.simulate_negentropic_process(%{})
    assert {:error, :physics_substrate_unavailable} = NDE.get_chaos_reduction_statistics()
    assert {:error, :physics_substrate_unavailable} = NDE.export_negentropic_model(:m1)
  end

  test "OPC client surface is quarantined" do
    assert {:error, :physics_substrate_unavailable} = OPC.compile_observer_physics(%{}, %{})
    assert {:error, :physics_substrate_unavailable} = OPC.get_observer_status(:o1)
    assert {:error, :physics_substrate_unavailable} = OPC.get_all_observers()
    assert {:error, :physics_substrate_unavailable} = OPC.apply_observer_effect(:o1, %{}, %{})
    assert {:error, :physics_substrate_unavailable} = OPC.compile_deterministic_physics(%{})
    assert {:error, :physics_substrate_unavailable} = OPC.get_compilation_metrics()
    assert {:error, :physics_substrate_unavailable} = OPC.validate_observer_consistency(:o1)
    assert {:error, :physics_substrate_unavailable} = OPC.get_physics_stability_metrics()
    assert {:error, :physics_substrate_unavailable} = OPC.optimize_observer_physics(:o1, %{})
    assert {:error, :physics_substrate_unavailable} = OPC.export_physics_model(:m1)
  end

  test "IRD client surface is quarantined" do
    assert {:error, :physics_substrate_unavailable} = IRD.register_intervention(:i1, %{})
    assert {:error, :physics_substrate_unavailable} = IRD.dampen_resonance(:i1, %{})
    assert {:error, :physics_substrate_unavailable} = IRD.get_intervention_status(:i1)
    assert {:error, :physics_substrate_unavailable} = IRD.get_all_interventions()
    assert {:error, :physics_substrate_unavailable} = IRD.coordinate_distributed_intervention([], %{})
    assert {:error, :physics_substrate_unavailable} = IRD.get_resonance_damping_metrics()
    assert {:error, :physics_substrate_unavailable} = IRD.validate_intervention_safety(%{})
    assert {:error, :physics_substrate_unavailable} = IRD.calculate_resonance_potential(%{})
    assert {:error, :physics_substrate_unavailable} = IRD.get_system_coordination_status()
    assert {:error, :physics_substrate_unavailable} = IRD.publish_coordination_event(%{})
    assert {:error, :physics_substrate_unavailable} = IRD.subscribe_to_coordination_events(:s1)
  end

  test "TWP client surface is quarantined" do
    assert {:error, :physics_substrate_unavailable} = TWP.prune_temporal_states([])
    assert {:error, :physics_substrate_unavailable} = TWP.add_temporal_state(:s1, [1.0])
    assert {:error, :physics_substrate_unavailable} = TWP.get_temporal_states()
    assert {:error, :physics_substrate_unavailable} = TWP.calculate_temporal_coherence()
    assert {:error, :physics_substrate_unavailable} = TWP.prune_future_branches()
    assert {:error, :physics_substrate_unavailable} = TWP.get_temporal_metrics()
    assert {:error, :physics_substrate_unavailable} = TWP.validate_temporal_consistency()
    assert {:error, :physics_substrate_unavailable} = TWP.collapse_temporal_wavefunction(:s1)
    assert {:error, :physics_substrate_unavailable} = TWP.get_temporal_predictions()
  end
end