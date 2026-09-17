defmodule ObservationBus.CIL.Mission.MissionCertification do
  @moduledoc """
  Certifies missions at progressive readiness levels.

  Levels: experimental, verified, engineering_ready, production_ready,
  civilizational_ready.
  """
  use GenServer

  @table_name :cil_mission_certifications

  defstruct [:table, :total_certifications]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_certifications: 0}}
  end

  @doc "Certify a mission at a given level."
  @spec certify(String.t(), atom(), map()) :: {:ok, map()}
  def certify(mission_id, level, evidence \\ %{}) do
    GenServer.call(__MODULE__, {:certify, mission_id, level, evidence})
  end

  @doc "Get certification status for a mission."
  @spec get(String.t()) :: [map()]
  def get(mission_id) do
    @table_name
    |> :ets.match({mission_id, :"$1"})
    |> List.flatten()
  end

  @impl true
  def handle_call({:certify, mission_id, level, evidence}, _from, state) do
    cert = %{
      mission_id: mission_id, level: level, evidence: evidence,
      certified_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {mission_id, cert})
    {:reply, {:ok, cert}, %{state | total_certifications: state.total_certifications + 1}}
  end
end
