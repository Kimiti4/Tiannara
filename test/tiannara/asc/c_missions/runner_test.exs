defmodule Tiannara.ASC.CMissions.RunnerTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.CMissions.{Ledger, Runner}

  defp passing_gates(overrides \\ %{}) do
    gates = %{
      correctness: true,
      regressions_zero: true,
      performance_measured: true,
      safety: :PASS,
      memory_delta: 0.01,
      latency_delta: 0.25
    }

    Map.merge(gates, overrides)
  end

  describe "Ledger" do
    test "appends entries in order and is round-trippable" do
      dir = Path.join(System.tmp_dir!(), "asc_ledger_test_#{System.unique_integer([:positive])}")
      File.rm_rf!(dir)

      ledger = Ledger.init(dir)
      ledger = Ledger.record(ledger, :C0_START, %{mission: "test"})
      ledger = Ledger.record(ledger, :C6_VERDICT, %{decision: :REJECT, selected_hypothesis: nil})

      entries = Ledger.entries(ledger)
      assert length(entries) == 2
      assert Enum.map(entries, & &1.seq) == [1, 2]
      assert Enum.map(entries, & &1.phase) == [:C0_START, :C6_VERDICT]
      assert Enum.at(entries, 1).data.decision == :REJECT

      File.rm_rf!(dir)
    end
  end

  describe "compute_deltas/2" do
    test "computes memory and latency deltas from baseline vs candidate" do
      base = %{p50_ms: 100.0, memory_mb: 100.0}
      cand = %{p50_ms: 70.0, memory_mb: 105.0}

      assert Runner.compute_deltas(base, cand) == %{
               memory_delta: 0.05,
               latency_delta: 0.3
             }
    end

    test "negative latency delta means regression" do
      base = %{p50_ms: 100.0, memory_mb: 100.0}
      cand = %{p50_ms: 120.0, memory_mb: 100.0}

      assert Runner.compute_deltas(base, cand).latency_delta == -0.2
    end
  end

  describe "gate_status/1" do
    test "PASS only when every strict gate holds" do
      assert Runner.gate_status(passing_gates()) == :PASS
    end

    test "FAIL when correctness fails" do
      assert Runner.gate_status(passing_gates(%{correctness: false})) == :FAIL
    end

    test "FAIL when latency improvement below 15%" do
      assert Runner.gate_status(passing_gates(%{latency_delta: 0.14})) == :FAIL
    end

    test "FAIL when memory growth above 5%" do
      assert Runner.gate_status(passing_gates(%{memory_delta: 0.051})) == :FAIL
    end

    test "FAIL when performance was not measured" do
      assert Runner.gate_status(passing_gates(%{performance_measured: false})) == :FAIL
    end
  end

  describe "evaluate_verdict/1" do
    test "ACCEPTs the first hypothesis that passed every gate" do
      results = [
        %{hyp: %{id: "D1"}, validation: %{status: :FAIL}, branch: "b1"},
        %{hyp: %{id: "D2"}, validation: %{status: :PASS}, branch: "b2"},
        %{hyp: %{id: "D3"}, validation: %{status: :PASS}, branch: "b3"}
      ]

      assert {:ACCEPT, %{hyp: %{id: "D2"}, branch: "b2"}} = Runner.evaluate_verdict(results)
    end

    test "REJECTs when no hypothesis passed every gate" do
      results = [
        %{hyp: %{id: "D1"}, validation: %{status: :FAIL}, branch: "b1"},
        %{hyp: %{id: "D2"}, validation: %{status: :FAIL}, branch: "b2"}
      ]

      assert {:REJECT, nil} = Runner.evaluate_verdict(results)
    end

    test "REJECTs when a hypothesis could not be patched" do
      results = [
        %{hyp: %{id: "D1"}, validation: %{status: :PATCH_FAILED}, branch: "b1"},
        %{hyp: %{id: "D2"}, validation: %{status: :FAIL}, branch: "b2"}
      ]

      assert {:REJECT, nil} = Runner.evaluate_verdict(results)
    end
  end
end