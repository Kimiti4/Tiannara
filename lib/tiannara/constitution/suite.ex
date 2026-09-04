defmodule Tiannara.Constitution.InvariantResult do
  @moduledoc "Outcome of one invariant probe."
  defstruct [:id, :category, :description, :passed, :detail]
end

defmodule Tiannara.Constitution.SuiteRun do
  @moduledoc "A full run of the invariant suite with per-invariant results."
  defstruct [:suite_id, :ran_at, results: [], all_passed: false, failed: []]
end

defmodule Tiannara.Constitution.Suite do
  @moduledoc """
  Runs a set of constitutional invariant probes and produces a SuiteRun.
  A probe that raises is treated as a violation (never silently skipped).

  Constitutional basis: Verification First, "Detect anomalies", "Maintain
  audit trails", "Uncertainty should never be hidden."
  """

  alias Tiannara.Constitution.{Invariant, InvariantResult, SuiteRun}

  defstruct invariants: []

  def new(invariants) when is_list(invariants), do: %__MODULE__{invariants: invariants}

  def run(%__MODULE__{invariants: invs}, suite_id \\ nil) do
    results = Enum.map(invs, &run_one/1)
    failed = for r <- results, not r.passed, do: r.id

    %SuiteRun{
      suite_id: suite_id,
      ran_at: DateTime.utc_now(),
      results: results,
      all_passed: failed == [],
      failed: failed
    }
  end

  defp run_one(%Invariant{} = inv) do
    result =
      try do
        inv.probe.()
      rescue
        e -> {:error, {:probe_raised, Exception.message(e)}}
      catch
        kind, value -> {:error, {:probe_threw, kind, value}}
      end

    %InvariantResult{
      id: inv.id,
      category: inv.category,
      description: inv.description,
      passed: result == :ok,
      detail: detail(result)
    }
  end

  defp detail(:ok), do: :ok
  defp detail({:error, reason}), do: reason
  defp detail(other), do: {:unexpected, other}
end