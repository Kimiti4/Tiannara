defmodule Tiannara.Chaos.EpistemicIntegrityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Chaos.EpistemicIntegrity

  defp c(stage, id, parents \\ []), do: {:created, stage, id, parents}
  defp d(stage, id, kind, detail \\ nil), do: {:disposition, stage, id, kind, detail}

  test "clean recovery -> intact" do
    snap = %{
      events: [
        c(:observations, :o1),
        d(:observations, :o1, :promoted, :g1),
        c(:gaps, :g1, [:o1])
      ],
      checkpoints: [%{id: :c1, parent: nil}],
      discovery_ids: []
    }

    assert {:intact, _report} = EpistemicIntegrity.check(snap, snap)
  end

  test "silent deletion -> violated" do
    pre = %{
      events: [
        c(:observations, :o1),
        c(:observations, :o2)
      ],
      checkpoints: [%{id: :c1, parent: nil}],
      discovery_ids: []
    }

    post = %{pre | events: [c(:observations, :o1)]}

    assert {:violated, violations} = EpistemicIntegrity.check(pre, post)
    assert Enum.any?(violations, &(&1.kind == :silent_loss))
  end

  test "broken checkpoint lineage -> violated" do
    snap = %{
      events: [],
      checkpoints: [%{id: :c2, parent: :c_missing}],
      discovery_ids: []
    }

    assert {:violated, violations} = EpistemicIntegrity.check(snap, snap)
    assert Enum.any?(violations, &(&1.kind == :broken_lineage))
  end
end
