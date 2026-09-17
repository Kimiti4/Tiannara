defmodule ObservationBus.CIL.Mission.CampaignTracker do
  @moduledoc """
  Tracks individual research campaigns within missions.

  Each campaign represents a focused research thread with its own
  objectives, experiments, discoveries, TRL progression, and evidence.
  """
  use GenServer

  @table_name :cil_campaigns

  defstruct [:table, :total_campaigns]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_campaigns: 0}}
  end

  @doc "Start a new campaign under a mission."
  @spec start(String.t(), String.t(), map()) :: {:ok, String.t()}
  def start(mission_id, name, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:start, mission_id, name, metadata})
  end

  @doc "Record progress for a campaign."
  @spec progress(String.t(), String.t(), map()) :: :ok
  def progress(campaign_id, status, evidence \\ %{}) do
    GenServer.cast(__MODULE__, {:progress, campaign_id, status, evidence})
  end

  @doc "List campaigns for a mission."
  @spec list(String.t()) :: [map()]
  def list(mission_id) do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, c} -> c end)
    |> Enum.filter(&(&1.mission_id == mission_id))
  end

  @impl true
  def handle_call({:start, mission_id, name, metadata}, _from, state) do
    id = uuid_v4()
    campaign = %{
      id: id, mission_id: mission_id, name: name,
      status: :active, trl: 1,
      evidence: [], metadata: metadata,
      started_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {id, campaign})
    {:reply, {:ok, id}, %{state | total_campaigns: state.total_campaigns + 1}}
  end

  @impl true
  def handle_cast({:progress, campaign_id, status, evidence}, state) do
    case :ets.lookup(@table_name, campaign_id) do
      [{^campaign_id, campaign}] ->
        updated = %{campaign |
          status: status,
          trl: min(9, campaign.trl + 1),
          evidence: [evidence | campaign.evidence] |> Enum.take(50)
        }
        :ets.insert(@table_name, {campaign_id, updated})
      _ -> :ok
    end
    {:noreply, state}
  end

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
