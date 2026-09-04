defmodule Tiannara.Certification.Certificate do
  @moduledoc """
  The certification authority. Refuses to certify any subsystem while the
  constitutional invariant gate is closed OR any functional gate is not open.
  A certificate is only issued when every requirement is met — never to appear
  correct while something is wrong.

  Constitutional basis: "Never optimize for appearing correct. Optimize for
  being correct", "No feature is complete until it is validated", "Capability
  must never outpace verification."
  """

  alias Tiannara.Constitution.{Gate, SuiteRun}

  defstruct [:subsystem, :verdict, :invariant_verdict, :failed_invariants,
             :functional_gates, :issued_at, :reason]

  def certify(subsystem, %SuiteRun{} = run, opts \\ []) do
    functional_gates = Keyword.get(opts, :functional_gates, %{})
    invariant_verdict = Gate.verdict(run)

    closed_functional =
      functional_gates
      |> Enum.filter(fn {_k, v} -> v != :open end)
      |> Enum.map(&elem(&1, 0))

    cond do
      invariant_verdict != :gate_open ->
        {:refused,
         %__MODULE__{
           subsystem: subsystem,
           verdict: :not_certified,
           invariant_verdict: invariant_verdict,
           failed_invariants: run.failed,
           functional_gates: functional_gates,
           issued_at: DateTime.utc_now(),
           reason: {:constitutional_invariants_failed, run.failed}
         }}

      closed_functional != [] ->
        {:refused,
         %__MODULE__{
           subsystem: subsystem,
           verdict: :not_certified,
           invariant_verdict: invariant_verdict,
           failed_invariants: [],
           functional_gates: functional_gates,
           issued_at: DateTime.utc_now(),
           reason: {:functional_gates_closed, closed_functional}
         }}

      true ->
        {:certified,
         %__MODULE__{
           subsystem: subsystem,
           verdict: :certified,
           invariant_verdict: :gate_open,
           failed_invariants: [],
           functional_gates: functional_gates,
           issued_at: DateTime.utc_now(),
           reason: :all_requirements_met
         }}
    end
  end
end