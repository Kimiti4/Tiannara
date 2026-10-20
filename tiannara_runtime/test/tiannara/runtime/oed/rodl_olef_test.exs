defmodule Tiannara.Runtime.OED.RODL_OLEF_Test do
  use ExUnit.Case

  alias Tiannara.Runtime.RODL.DDL
  alias Tiannara.Runtime.RODL.SemanticTranslator
  alias Tiannara.Runtime.OLEF.Field
  alias Tiannara.Runtime.OLEF.CPT
  alias Tiannara.Runtime.OLEF.RLDN

  setup do
    unless Process.whereis(Field), do: start_supervised!(Field)
    unless Process.whereis(DDL), do: start_supervised!(DDL)

    :ok = Field.reset()
    :ok = DDL.reset()
    :ok
  end

  test "DDL intercepts exploit and offloads compute" do
    assert {:ok, primitive} =
             DDL.register_primitive(
               "tier_1_beta",
               %{gravity: 3.7, hydrology: :frozen, biosphere_seed: :silicate},
               900.0
             )

    assert primitive.pressure == 900.0

    assert {:ok, delegation} = DDL.intercept_pdo_exploit("tier_3_obs", 100.0)
    assert delegation.tier_3_observer == "tier_3_obs"
    assert delegation.tier_1_manifold == "tier_1_beta"
    assert delegation.harvested_compute > 0.0
    assert delegation.disguised_payload.metadata.original_tier == 1
    assert delegation.disguised_payload.metadata.target_tier == 3
  end

  test "OLEF tracks pressure and calculates equilibrium" do
    Field.update_pressure("manifold_1", 10.0)
    Field.update_pressure("manifold_2", 20.0)

    # Wait for casts to process
    Process.sleep(200)

    {:ok, avg} = Field.get_equilibrium_drift()
    assert avg == 15.0
  end

  test "OLEF triggers redistribution routes on high pressure" do
    Field.update_pressure("low_p", 10.0)
    Field.update_pressure("mid_p", 40.0)
    # This should trigger GradientSolver.redistribute
    Field.update_pressure("high_p", 1500.0)

    Process.sleep(200)
    {:ok, avg} = Field.get_equilibrium_drift()
    assert avg == 516.6666666666666

    snapshot = Field.snapshot()
    assert length(snapshot.diffusion_routes) == 2
    assert Enum.any?(snapshot.diffusion_routes, &(&1.target == "low_p"))
  end

  test "semantic translator creates dual-frame disguised payload" do
    payload =
      SemanticTranslator.translate(%{gravity: 9.81},
        translation_efficiency: 0.9,
        drift_entropy: 0.2
      )

    assert payload.encoded_compute_graph.semantic_mask == :tier_3_counterfactual_anomaly
    assert payload.dual_frame_consistency.local_determinism.short_term_predictability > 0.9
    assert payload.dual_frame_consistency.global_drift_entropy.parameter_mutation == 0.2
    assert SemanticTranslator.estimate_harvest(100.0, payload) == 90.0
  end

  test "CPT converts observer metrics into pressure tensor" do
    tensor =
      CPT.calculate_stress(%{
        computational_load: 100.0,
        exploit_intensity: 50.0,
        delegation_burden: 25.0,
        coherence_debt: 10.0
      })

    assert tensor.pressure == 236.5
    assert CPT.pressure(%{computational_load: 10.0}) == 12.0
  end

  test "RLDN diffuses load toward lower pressure targets" do
    assert {:ok, routes} =
             RLDN.diffuse(%{source: "high_p", load: 100.0}, %{
               "low_p" => 10.0,
               "mid_p" => 40.0
             })

    low_route = Enum.find(routes, &(&1.target == "low_p"))
    mid_route = Enum.find(routes, &(&1.target == "mid_p"))

    assert low_route.load > mid_route.load
    assert_in_delta Enum.sum(Enum.map(routes, & &1.load)), 100.0, 0.0001
  end
end
