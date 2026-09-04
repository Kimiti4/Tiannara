defmodule Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def review(decisions) do
    GenServer.call(__MODULE__, {:review, decisions}, 30_000)
  end

  def pending_decisions, do: GenServer.call(__MODULE__, :pending)

  @impl true
  def init(_opts), do: {:ok, %{reviews: 0, approved: 0, gated: 0, pending: []}}

  @impl true
  def handle_call({:review, decisions}, _from, state) do
    {approved, gated} = Enum.split_with(decisions, fn d ->
      not Map.get(d, :requires_human_approval, false)
    end)

    if gated != [] do
      Logger.info("ConstitutionalGovernance: #{length(gated)} decisions require human approval")
    end

    result = %{
      approved_decisions: approved, gated_decisions: gated,
      total_reviewed: length(decisions), auto_approved: length(approved),
      requires_human: length(gated), reviewed_at: DateTime.utc_now()
    }

    {:reply, {:ok, result}, %{state |
      reviews: state.reviews + 1, approved: state.approved + length(approved),
      gated: state.gated + length(gated), pending: gated ++ state.pending
    }}
  end

  def handle_call(:pending, _from, state), do: {:reply, state.pending, state}
  def handle_info(_, state), do: {:noreply, state}
end
