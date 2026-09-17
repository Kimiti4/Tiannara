defmodule Tiannara.Discovery.DiscoveryGenerationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.{Pipeline, Certificate}

  @moduletag :discovery_generation

  defp fertile_seed do
    %{
      quantity: :x,
      observations: [%{value: 10, source: :a}, %{value: 20, source: :b}],
      world: %{x: 10},
      tolerance: 1,
      reproducibility_runs: 3,
      discovery_threshold: 0.7
    }
  end

  test "a fertile epistemic environment yields a validated, provenance-preserving discovery" do
    run = Pipeline.run(fertile_seed())
    cert = Certificate.issue(run)

    assert cert.validated_discoveries >= 1
    assert cert.silent_losses == 0
    assert cert.funnel_completeness == 100.0
    assert cert.verdict == :discovery_generated

    [disc | _] = run.context.discoveries
    assert disc.confidence >= fertile_seed().discovery_threshold

    stages = Enum.map(disc.content.provenance, &elem(&1, 0))
    assert :observations in stages
    assert :evidence_generated in stages
    assert :discovery_candidates in stages
  end

  test "the discovery discriminates competing hypotheses (one validated, one rejected)" do
    run = Pipeline.run(fertile_seed())
    hyps = Enum.filter(run.artifacts, &(&1.stage == :hypotheses))
    assert length(hyps) == 2

    rejected =
      Enum.filter(run.events, fn
        {:disposition, :hypotheses, _id, :rejected, _} -> true
        _ -> false
      end)

    assert length(rejected) == 1
  end

  test "certificate renders the guarantee block" do
    run = Pipeline.run(fertile_seed())
    text = Certificate.render(Certificate.issue(run))

    assert text =~ "Validated discoveries"
    assert text =~ "Funnel completeness"
    assert text =~ "Silent losses"
    assert text =~ "VERDICT: discovery_generated"
  end
end
