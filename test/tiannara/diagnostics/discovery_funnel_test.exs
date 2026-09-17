defmodule Tiannara.Diagnostics.DiscoveryFunnelTest do
  use ExUnit.Case, async: true

  alias Tiannara.Diagnostics.DiscoveryFunnel
  alias Tiannara.Diagnostics.EventSource.Mock

  # --- helpers -------------------------------------------------------------
  defp c(stage, id, parents \\ []), do: {:created, stage, id, parents}
  defp d(stage, id, kind, detail \\ nil), do: {:disposition, stage, id, kind, detail}

  # Builds a full 12-stage promoted chain from a list of 12 ids.
  defp full_chain(ids) when length(ids) == 12 do
    tuples = Enum.zip(DiscoveryFunnel.stages(), ids)

    created =
      tuples
      |> Enum.with_index()
      |> Enum.map(fn {{stage, id}, i} ->
        parents = if i == 0, do: [], else: [elem(Enum.at(tuples, i - 1), 1)]
        c(stage, id, parents)
      end)

    promoted =
      tuples
      |> Enum.with_index()
      |> Enum.reject(fn {_t, i} -> i == length(tuples) - 1 end)
      |> Enum.map(fn {{stage, id}, i} ->
        {_next_stage, next_id} = Enum.at(tuples, i + 1)
        d(stage, id, :promoted, next_id)
      end)

    created ++ promoted
  end

  # --- tests ---------------------------------------------------------------

  # The "17 hypotheses / 0 scheduled" scenario: fully EXPLAINED.
  test "fully EXPLAINED zero -> :validation_rejected, no violations" do
    ids = [:o1, :g1, :h1, :h2, :h3, :h4, :h5, :h6, :h7, :h8, :h9, :h10, :h11, :h12, :h13, :h14, :h15, :h16, :h17]

    created = [
      c(:observations, :o1),
      d(:observations, :o1, :promoted, :g1),
      c(:gaps, :g1, [:o1]),
      d(:gaps, :g1, :promoted, :h1)
    ] ++ Enum.map(1..17, fn i -> c(:hypotheses, :"h#{i}", [:g1]) end)

    rejections =
      (Enum.map(1..12, fn i -> d(:hypotheses, :"h#{i}", :rejected, :insufficient_evidence) end) ++
         Enum.map(13..15, fn i -> d(:hypotheses, :"h#{i}", :rejected, :constitutional_veto) end) ++
         Enum.map(16..17, fn i -> d(:hypotheses, :"h#{i}", :rejected, :duplicate) end))

    events = created ++ rejections
    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:hypotheses] == 17
    assert funnel.counts[:experiments_scheduled] == 0
    assert funnel.violations == []
    assert funnel.zero_state == :validation_rejected
    assert funnel.unexplained[:hypotheses] == 0
  end

  test "SILENT LOSS zero -> :pipeline_blocked, violations present" do
    events = [
      c(:observations, :o1),
      d(:observations, :o1, :promoted, :g1),
      c(:gaps, :g1, [:o1]),
      d(:gaps, :g1, :promoted, :h1),
      c(:hypotheses, :h1, [:g1])
      # h1 has NO disposition -> silent loss
    ]

    events = events ++ Enum.map(2..17, fn i -> c(:hypotheses, :"h#{i}", [:g1]) end)

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:hypotheses] == 17
    assert funnel.counts[:experiments_scheduled] == 0
    assert funnel.unexplained[:hypotheses] == 17
    assert funnel.zero_state == :pipeline_blocked
    assert Enum.any?(funnel.violations, &(&1.stage == :hypotheses))
  end

  test "no signal -> :no_signal" do
    events = [
      c(:observations, :o1),
      d(:observations, :o1, :closed, :no_gap)
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:observations] == 1
    assert funnel.counts[:gaps] == 0
    assert funnel.violations == []
    assert funnel.zero_state == :no_signal
  end

  test "discovery present -> :discoveries_present" do
    ids = [:o1, :g1, :h1, :r1, :p1, :s1, :st1, :c1, :e1, :ki1, :dc1, :vd1]
    events = full_chain(ids)

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:validated_discoveries] == 1
    assert funnel.zero_state == :discoveries_present
    assert funnel.violations == []
  end

  test "the three zero states are distinguishable" do
    # pipeline blocked (silent loss)
    blocked =
      DiscoveryFunnel.audit(
        Mock.new([
          c(:observations, :o1),
          d(:observations, :o1, :promoted, :g1),
          c(:gaps, :g1, [:o1]),
          d(:gaps, :g1, :promoted, :h1),
          c(:hypotheses, :h1, [:g1])
        ])
      )

    assert blocked.zero_state == :pipeline_blocked

    # validation rejected (all explained)
    rejected =
      DiscoveryFunnel.audit(
        Mock.new([
          c(:observations, :o1),
          d(:observations, :o1, :promoted, :g1),
          c(:gaps, :g1, [:o1]),
          d(:gaps, :g1, :promoted, :h1),
          c(:hypotheses, :h1, [:g1]),
          d(:hypotheses, :h1, :rejected, :insufficient_evidence)
        ])
      )

    assert rejected.zero_state == :validation_rejected

    # no signal (no gap)
    no_signal =
      DiscoveryFunnel.audit(
        Mock.new([
          c(:observations, :o1),
          d(:observations, :o1, :closed, :no_gap)
        ])
      )

    assert no_signal.zero_state == :no_signal

    refute blocked.zero_state == rejected.zero_state
    refute rejected.zero_state == no_signal.zero_state
  end
end
