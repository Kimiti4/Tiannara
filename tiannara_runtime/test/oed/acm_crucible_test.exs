defmodule Tiannara.OED.ACM.CrucibleTest do
  use ExUnit.Case, async: false

  alias Tiannara.OED.ACM.{
    CivilizationGenerator,
    CivilizationDiscriminator,
    OntologyTranslation,
    CausalAdversary,
    RobustnessScorer,
    ObserverExploitEngine,
    LatentSimulation
  }

  setup do
    start_supervised!(Tiannara.OED.ACM.CivilizationGenerator)
    start_supervised!(Tiannara.OED.ACM.CivilizationDiscriminator)
    start_supervised!(Tiannara.OED.ACM.ObserverExploitEngine)
    start_supervised!(Tiannara.OED.ACM.LatentSimulation)
    :ok
  end

  describe "CivilizationGenerator and CivilizationDiscriminator" do
    test "generator injects flaw and discriminator isolates it" do
      rule = %{
        type: :compression_policy,
        body: {:apply, :adaptive, [:conservative]},
        invariants: [:causal_conservation]
      }

      flawed = CivilizationGenerator.inject_adversarial_flaw(rule, :circular)
      assert :circular_reasoning in flawed.invariants

      assert {:error, reason} = CivilizationDiscriminator.scrutinize(flawed)
      assert reason =~ "Circular logic loop"
    end
  end

  describe "ObserverExploitEngine" do
    test "detects privilege escalation attempt" do
      unsafe_rule = %{
        type: :compression_policy,
        body: {:apply, :bypass_osl, [123]}
      }

      assert {:error, reason} = ObserverExploitEngine.simulate_exploit(unsafe_rule)
      assert reason =~ "Privilege escalation"
    end
  end

  describe "LatentSimulation and RobustnessScorer" do
    test "simulates state projection and scores rule" do
      rule = %{
        type: :compression_policy,
        body: {:apply, :adaptive, []}
      }

      assert {:ok, metrics} = LatentSimulation.simulate(rule)
      assert metrics.stability == 0.95

      score = RobustnessScorer.score(rule, metrics)
      assert score > 0.8
    end
  end
end
