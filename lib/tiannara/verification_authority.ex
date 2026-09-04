defmodule Tiannara.VerificationAuthority do
  @moduledoc """
  Independent constitutional service for verifying engineering proposals.

  Constitutional mandate: "Verification First. No feature is complete
  until it is validated."

  CRITICAL: This subsystem is NOT owned by ProposalGenerator.
  It is an independent authority, analogous to the Constitutional Council.

  Responsibilities:
  - Deterministic replay of the failure
  - Regression test synthesis
  - Simulation of side effects
  - Constitutional compliance verification

  Verification evidence is IMMUTABLE.
  """
  use GenServer
  require Logger

  alias Tiannara.Engineering.Proposal
  alias Tiannara.Engineering.Events

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Verify an engineering proposal. Returns a VerificationResult struct.

  Verification never mutates the proposal — it attaches a verification
  record that the ProposalRegistry can reference.
  """
  def verify(%Proposal{} = proposal) do
    GenServer.call(__MODULE__, {:verify, proposal}, 30_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{verified_count: 0, passed_count: 0, failed_count: 0}}
  end

  @impl true
  def handle_call({:verify, proposal}, _from, state) do
    Logger.info("[VerificationAuthority] Verifying proposal #{proposal.id} for #{proposal.affected_module}")

    result = %Tiannara.Verification.Result{
      proposal_id: proposal.id,
      reproduction: attempt_reproduction(proposal),
      regression_tests: synthesize_regression_tests(proposal),
      simulation: simulate_side_effects(proposal),
      constitutional_compliance: check_constitutional_compliance(proposal),
      verified_at: DateTime.utc_now(),
      immutable: true
    }

    if Tiannara.Verification.Result.passed?(result) do
      Events.emit(:proposal_verified, proposal.id, %{passed: true, result: result})
    else
      Events.emit(:proposal_verified, proposal.id, %{passed: false, result: result})
    end

    {:reply, result, %{
      state
      | verified_count: state.verified_count + 1,
        passed_count: state.passed_count + if(Tiannara.Verification.Result.passed?(result), do: 1, else: 0),
        failed_count: state.failed_count + if(Tiannara.Verification.Result.passed?(result), do: 0, else: 1)
    }}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp attempt_reproduction(proposal) do
    failure = proposal.observed_failure
    # Truthful: no deterministic replay exists for reproduction in this
    # configuration. Reproduction is not claimed unless actually executed.
    %{reproduced: false, method: :unavailable, failure_type: inspect(failure.exception), evidence: []}
  end

  defp synthesize_regression_tests(proposal) do
    # Truthful: no regression suite has been synthesized or executed.
    %{test_synthesized: false, module: proposal.affected_module, count: 0, all_passing: false}
  end

  defp simulate_side_effects(proposal) do
    %{risk_level: proposal.side_effect_assessment || :unknown, simulated_scenarios: 0}
  end

  defp check_constitutional_compliance(proposal) do
    # Truthful: constitutional compliance is not independently assessed here.
    %{compliant: false, clauses_checked: 0, violations: [], reason: :not_independently_assessed}
  end
end
