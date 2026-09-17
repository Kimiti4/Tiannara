defmodule TiannaraRuntime.IRD.Consumer do
  @moduledoc """
  Phase 5F.12 — IRD Intervention Consumer

  Ingests stabilizer proposals, computes interference, reserves budget,
  and schedules or defers execution via the IRD pipeline.
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.IRD.{InterferenceMatrix, PhaseScheduler, BudgetController, QuiescenceManager, Feedback}
  alias TiannaraRuntime.NATS.Publisher

  @proposal_subject "tiannara.ird.interventions"
  @execute_subject "tiannara.ird.execute.ird_consumer"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("📥 [IRD] Intervention consumer initialized")
    {:ok, %{proposals: [], last_publish: nil}}
  end

  @doc "Submit a stabilizer proposal to the IRD pipeline."
  def submit_proposal(proposal) when is_map(proposal) do
    GenServer.cast(__MODULE__, {:submit_proposal, proposal})
  end

  @impl true
  def handle_cast({:submit_proposal, proposal}, state) do
    proposal = normalize_proposal(proposal)
    proposals = [proposal | state.proposals]

    publish_proposal(proposal)
    interference = InterferenceMatrix.compute(proposals)

    if interference.max_value > InterferenceMatrix.critical_threshold() do
      QuiescenceManager.trigger_global_quiescence(interference)
      Feedback.record_outcome(%{proposal: proposal, status: :deferred, reason: :high_interference, interference: interference})
      {:noreply, %{state | proposals: proposals}}
    else
      case BudgetController.reserve(proposal) do
        :ok ->
          delay = PhaseScheduler.compute_delay(interference)
          schedule_execution(proposal, delay)
          Feedback.record_outcome(%{proposal: proposal, status: :scheduled, delay_ms: delay})
          {:noreply, %{state | proposals: proposals}}

        {:deferred, reason} ->
          Logger.debug("[IRD] Proposal deferred due to budget: #{inspect(reason)}")
          Feedback.record_outcome(%{proposal: proposal, status: :deferred, reason: reason})
          {:noreply, %{state | proposals: proposals}}
      end
    end
  end

  @impl true
  def handle_info({:execute_proposal, proposal}, state) do
    publish_execute(proposal)
    {:noreply, state}
  end

  defp normalize_proposal(proposal) do
    proposal
    |> Map.put_new(:observer_id, Map.get(proposal, :observer_id, "unknown_observer"))
    |> Map.put_new(:priority, Map.get(proposal, :priority, 0.5))
    |> Map.put_new(:intensity, Map.get(proposal, :intensity, 0.25))
    |> Map.put_new(:timestamp, System.system_time(:millisecond))
  end

  defp publish_proposal(proposal) do
    payload = %{
      event: :proposal_received,
      proposal: proposal,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.debug("📤 [IRD] Publishing proposal to #{@proposal_subject}")
    Publisher.publish(@proposal_subject, Jason.encode!(payload))
  end

  defp schedule_execution(proposal, delay_ms) do
    Process.send_after(self(), {:execute_proposal, proposal}, delay_ms)
  end

  defp publish_execute(proposal) do
    payload = %{
      event: :execute_proposal,
      proposal: proposal,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.info("🚀 [IRD] Executing proposal for #{proposal.observer_id} after delay")
    Publisher.publish(@execute_subject, Jason.encode!(payload))
  end
end
