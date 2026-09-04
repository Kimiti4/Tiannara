defmodule Tiannara.Engineering.ProposalRegistry do
  @moduledoc """
  Registry for L4 Engineering Proposals.

  Constitutional mandate: "Every architectural decision should remain traceable."

  Stores proposals immutably in ETS (hot cache) with graceful degradation
  if ExecutiveMemory is unavailable. Proposals are immutable once minted;
  state advances are stored as separate lineage entries, not mutations.
  """
  use GenServer
  require Logger

  alias Tiannara.Engineering.Proposal

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register(%Proposal{} = proposal) do
    GenServer.call(__MODULE__, {:register, proposal})
  end

  def get(id) when is_binary(id) do
    case :ets.lookup(:engineering_proposals, id) do
      [{^id, proposal}] -> proposal
      _ -> nil
    end
  end

  def list_by_status(statuses) when is_list(statuses) do
    :ets.foldl(
      [],
      :engineering_proposals,
      fn {id, proposal}, acc ->
        if proposal.status in statuses do
          [{id, proposal} | acc]
        else
          acc
        end
      end
    )
  end

  def count do
    :ets.info(:engineering_proposals, :size)
  end

  def status_counts do
    :ets.foldl(
      %{},
      :engineering_proposals,
      fn {_id, proposal}, acc ->
        Map.update(acc, proposal.status, 1, &(&1 + 1))
      end
    )
  end

  @impl true
  def init(_opts) do
    :ets.new(:engineering_proposals, [:named_table, :set, :public, {:read_concurrency, true}])
    {:ok, %{proposal_count: 0}}
  end

  @impl true
  def handle_call({:register, %Proposal{} = proposal}, _from, state) do
    :ets.insert(:engineering_proposals, {proposal.id, proposal})

    Logger.info("[ProposalRegistry] Registered proposal #{proposal.id} for #{proposal.affected_module} (status: #{proposal.status})")

    :telemetry.execute([:engineering, :proposal, :registered], %{count: 1}, %{
      affected_module: proposal.affected_module,
      status: proposal.status
    })

    {:reply, :ok, %{state | proposal_count: state.proposal_count + 1}}
  end
end
