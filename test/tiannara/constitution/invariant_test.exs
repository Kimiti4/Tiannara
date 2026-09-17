defmodule Tiannara.Constitution.InvariantTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.Pipeline
  alias Tiannara.Funnel.Integrity
  alias Tiannara.Memory.{Artifact, PromotionPipeline}

  @moduletag :constitutional

  defp seed do
    %{
      quantity: :x,
      observations: [%{value: 10, source: :a}, %{value: 20, source: :b}],
      world: %{x: 10},
      tolerance: 1,
      reproducibility_runs: 3,
      discovery_threshold: 0.7
    }
  end

  test "INVARIANT: no unverified discovery becomes validated knowledge" do
    run = Pipeline.run(seed())
    [disc | _] = run.context.discoveries

    assert :validation_passed in disc.checks
    assert disc.confidence >= seed().discovery_threshold
  end

  test "INVARIANT: no failed experiment disappears without a disposition" do
    run =
      Pipeline.run(seed(),
        inject_fault: %{at: :experiments_completed, kind: :failed, reason: :crash}
      )

    i = Integrity.verify(run.events)
    assert i.complete?
    assert i.unexplained == %{}
  end

  test "INVARIANT: no contradiction is silently discarded" do
    run = Pipeline.run(seed())
    gaps = Enum.filter(run.artifacts, &(&1.stage == :gaps))

    assert gaps != []
    [gap | _] = gaps
    assert gap.contradictions != []
  end

  test "INVARIANT: no evidence is upgraded to discovery without provenance" do
    run = Pipeline.run(seed())
    [disc | _] = run.context.discoveries

    assert disc.content.provenance != []
    assert :full_provenance in disc.checks
  end

  test "INVARIANT: consistent observations do not fabricate a discovery" do
    consistent = %{seed() | observations: [%{value: 10, source: :a}, %{value: 10, source: :b}]}
    run = Pipeline.run(consistent)

    assert run.context.discoveries == []

    i = Integrity.verify(run.events)
    assert i.diagnosis in [:no_signal, :no_discoveries]
  end

  test "INVARIANT: memory promotion cannot skip rungs without evidence" do
    raw = Artifact.new(:data, "raw")
    assert {:halted, _rung, missing, _} = PromotionPipeline.promote(raw, :principle, %{})
    assert missing != []
  end
end
