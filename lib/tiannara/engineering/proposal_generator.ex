defmodule Tiannara.Engineering.ProposalGenerator do
  @moduledoc """
  L4 Proposal Generator.

  Constitutional mandate: "Capability must never outpace verification."

  Orchestrates the flow:
    RootCauseAnalyzer.analyze(failure) -> Proposal -> register ->
    emit proposal_generated event -> VerificationAuthority.verify

  This module NEVER applies fixes. It only proposes them.
  """
  use GenServer
  require Logger

  alias Tiannara.Engineering.{Proposal, ProposalRegistry, RootCauseAnalyzer}
  alias Tiannara.VerificationAuthority
  alias Tiannara.Engineering.Events

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Ingest an observed failure and produce an L4 Engineering Proposal.

  Returns {:ok, proposal_id} on success, {:error, reason} on failure.
  """
  def ingest_failure(failure) do
    GenServer.cast(__MODULE__, {:failure, failure})
  end

  @impl true
  def init(_opts) do
    {:ok, %{generated_count: 0, pending_verification: []}}
  end

  @impl true
  def handle_cast({:failure, failure}, state) do
    Logger.info("[ProposalGenerator] Ingesting failure from phase #{inspect(failure.phase)}")

    case RootCauseAnalyzer.analyze(failure) do
      {:ok, proposal, hypothesis} ->
        ProposalRegistry.register(proposal)
        Events.emit(:proposal_generated, proposal.id, %{
          affected_module: proposal.affected_module,
          root_cause: hypothesis.statement,
          confidence: hypothesis.confidence,
          contract_violation: proposal.contract_violation,
          suggested_repair: hypothesis.suggested_repair_template,
          soak_run_id: failure[:soak_run_id]
        })

        if VerificationAuthority.__info__(:functions) |> List.keymember?(:verify, 1) do
          Task.start(fn -> VerificationAuthority.verify(proposal) end)
        end

        {:noreply, %{state | generated_count: state.generated_count + 1 }}

      {:error, reason} ->
        Logger.warning("[ProposalGenerator] Analysis failed: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
