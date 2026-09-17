defmodule Tiannara.Discovery.AdversarialFunnelTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.Pipeline
  alias Tiannara.Funnel.Integrity

  @moduletag :adversarial_funnel

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

  test "blocking the scheduler produces an explicit BLOCKED diagnosis, not a silent zero" do
    run =
      Pipeline.run(seed(),
        inject_fault: %{at: :experiments_scheduled, kind: :blocked, reason: :scheduler_unavailable}
      )

    i = Integrity.verify(run.events)

    assert i.complete?
    assert i.terminal_discoveries == 0
    assert i.diagnosis == :blocked
    assert [%{stage: :experiments_proposed, kind: :blocked} | _] = i.blockages
    assert hd(i.blockages).reasons == %{scheduler_unavailable: 1}
  end

  test "a failed evidence-generation stage is diagnosed as failed, not lost" do
    run =
      Pipeline.run(seed(),
        inject_fault: %{at: :evidence_generated, kind: :failed, reason: :instrument_fault}
      )

    i = Integrity.verify(run.events)
    assert i.complete?
    assert i.diagnosis == :blocked
    assert hd(i.blockages).kind == :failed
  end

  test "every breakable transition yields an explicit diagnosis and no silent loss" do
    for stage <- Pipeline.stages() -- [:observations, :validated_discoveries] do
      run =
        Pipeline.run(seed(),
          inject_fault: %{at: stage, kind: :blocked, reason: :test_break}
        )

      i = Integrity.verify(run.events)

      assert i.complete?,
             "breaking at #{stage} must not create silent loss"

      assert i.diagnosis in [
               :blocked,
               :no_signal,
               :validation_rejected,
               :advanced_but_empty,
               :no_discoveries
             ],
             "breaking at #{stage} should yield an explicit diagnosis, got " <>
               "#{inspect(i.diagnosis)}"
    end
  end
end
