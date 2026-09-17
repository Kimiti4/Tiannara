defmodule Tiannara.Discovery.Adaptive.AdaptivePropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.Adaptive.{BayesianPrioritizer, OpportunityCostEstimator}
  alias Tiannara.Discovery.{Discovery, DiscoveryScore}
  alias Tiannara.Discovery.Domain.KnowledgeGap

  defp build_discovery(domain, severity, impact) do
    gap = KnowledgeGap.new(%{
      domain: domain,
      description: "prop test",
      severity: severity,
      estimated_impact: impact,
      source: :epistemic_integrity
    })
    Discovery.from_gap(gap)
  end

  describe "BayesianPrioritizer invariants" do
    property "priority is always in [0.0, 1.0]" do
      check all severity <- member_of([:low, :medium, :high, :critical]),
                impact <- float(min: 0.0, max: 1.0) do
        disc = build_discovery(:test_domain, severity, impact)
        priority = BayesianPrioritizer.prioritize(disc, [])

        assert priority >= 0.0
        assert priority <= 1.0
      end
    end

    property "priority with history is still bounded" do
      check all severity <- member_of([:low, :medium, :high, :critical]) do
        disc = build_discovery(:test_domain, severity, 0.7)

        history = Enum.map(1..5, fn _ ->
          d = build_discovery(:test_domain, :medium, 0.5)
          %{d | status: :completed, confidence: 0.8}
        end)

        priority = BayesianPrioritizer.prioritize(disc, history)
        assert priority >= 0.0
        assert priority <= 1.0
      end
    end

    property "learn/3 always increases total_observations" do
      check all outcome <- member_of([:success, :failure]) do
        model = BayesianPrioritizer.init_model()
        disc = build_discovery(:test_domain, :high, 0.8)

        updated = BayesianPrioritizer.learn(model, disc, outcome)
        assert updated.total_observations == 1
      end
    end
  end

  describe "OpportunityCostEstimator invariants" do
    property "opportunity cost is always non-negative" do
      check all count <- integer(1..5) do
        chosen = build_discovery(:domain_a, :medium, 0.5)
        alternatives = Enum.map(1..count, fn i ->
          build_discovery(:"domain_#{i}", :high, 0.8)
        end)

        cost = OpportunityCostEstimator.estimate(chosen, alternatives)
        assert cost >= 0.0
      end
    end

    property "EVI is always in [0.0, 1.0]" do
      check all severity <- member_of([:low, :medium, :high, :critical]),
                impact <- float(min: 0.0, max: 1.0) do
        disc = build_discovery(:test, severity, impact)
        evi = OpportunityCostEstimator.expected_value_of_information(disc)

        assert evi >= 0.0
        assert evi <= 1.0
      end
    end
  end
end
