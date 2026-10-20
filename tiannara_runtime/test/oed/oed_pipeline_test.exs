defmodule Tiannara.OED.Validation.AdversarialPipelineTest do
  use ExUnit.Case, async: false

  alias Tiannara.OED.Validation.AdversarialPipeline
  alias Tiannara.OED.BudgetController
  alias Tiannara.OED.Quarantine.QuarantineRegistry

  setup do
    start_supervised!(Tiannara.OED.BudgetController)
    start_supervised!(Tiannara.OED.OAVL.OntologyValidator)
    start_supervised!(Tiannara.OED.OAVL.HiddenAssumptionDetector)
    start_supervised!(Tiannara.OED.ACM.CivilizationGenerator)
    start_supervised!(Tiannara.OED.ACM.CivilizationDiscriminator)
    start_supervised!(Tiannara.OED.ACM.ObserverExploitEngine)
    start_supervised!(Tiannara.OED.ACM.LatentSimulation)
    start_supervised!(Tiannara.OED.OAVL.SemanticDriftAnalyzer)
    start_supervised!(Tiannara.OED.OAVL.EpistemicCost)
    start_supervised!(Tiannara.OED.UMSC.StabilityController)
    start_supervised!(Tiannara.OED.OAVL.GlobalizationGate)
    start_supervised!(Tiannara.OED.Quarantine.QuarantineRegistry)
    start_supervised!(Tiannara.OED.Quarantine.ContradictionTracker)
    start_supervised!(Tiannara.OED.Quarantine.SuspendedTheories)
    :ok
  end

  describe "OED Adversarial Pipeline" do
    test "processes clean configurations and globalizes them as globally safe" do
      clean_rule = %{
        type: :compression_policy,
        body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
        invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
      }

      assert {:ok, :globally_safe} = AdversarialPipeline.process(clean_rule, 0.6)
    end

    test "quarantines rules failing Tier 1 symbolic OAVL checks" do
      faulty_rule = %{
        type: :diffusion_policy,
        body: {:if, true, {:if, true, {:if, true, {:if, true, {:if, true, {:if, true, :ignore}}}}}},
        invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
      }

      assert {:ok, :quarantined} = AdversarialPipeline.process(faulty_rule, 0.6)

      quarantined_list = QuarantineRegistry.list_quarantined()
      assert Enum.any?(quarantined_list, &(&1.theory.type == :diffusion_policy))
    end

    test "rejects rules with poor robustness scores" do
      bad_rule = %{
        type: :diffusion_policy,
        body: {:if, true, {:diffuse, :pressure_field, 0.05, {:cap, -10.0}}, :ignore}, # Negative cap limit
        invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
      }

      assert {:error, reason} = AdversarialPipeline.process(bad_rule, 0.6)
      assert reason =~ "rejected by globalization gate" or reason =~ "unconstrained division" or reason =~ "regress"
    end
  end

  describe "OED BudgetController Integration" do
    test "allocates and releases VRAM/branch counters successfully" do
      assert :ok == BudgetController.allocate(:vram, 512.0)
      usage = BudgetController.current_usage()
      assert usage.vram_used == 512.0

      assert :ok == BudgetController.release(:vram, 512.0)
      new_usage = BudgetController.current_usage()
      assert new_usage.vram_used == 0.0
    end
  end
end
