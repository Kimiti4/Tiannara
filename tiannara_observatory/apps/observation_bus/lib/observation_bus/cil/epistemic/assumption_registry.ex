defmodule ObservationBus.CIL.Epistemic.AssumptionRegistry do
  @moduledoc """
  Every subsystem exposes its assumptions for tracking and auditing.

  Assumptions are tagged with subsystem, domain, criticality, and
  verification status. Mission Control can view all assumptions
  across the entire constitutional system.
  """
  use GenServer

  @table_name :cil_assumptions

  defstruct [:table, :total_assumptions]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_assumptions: 0}}
  end

  @doc "Register an assumption."
  @spec register(String.t(), String.t(), atom(), map()) :: {:ok, String.t()}
  def register(subsystem, description, criticality \\ :medium, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register, subsystem, description, criticality, metadata})
  end

  @doc "Verify an assumption with evidence."
  @spec verify(String.t(), String.t(), String.t()) :: :ok
  def verify(id, evidence, verifier) do
    GenServer.cast(__MODULE__, {:verify, id, evidence, verifier})
  end

  @doc "List assumptions, optionally filtered by subsystem or criticality."
  @spec list(keyword()) :: [map()]
  def list(filters \\ []) do
    subsystem = Keyword.get(filters, :subsystem)
    criticality = Keyword.get(filters, :criticality)

    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, a} -> a end)
    |> Enum.filter(fn a ->
      (is_nil(subsystem) or a.subsystem == subsystem) and
      (is_nil(criticality) or a.criticality == criticality)
    end)
    |> Enum.sort_by(& &1.criticality, :desc)
  end

  @impl true
  def handle_call({:register, subsystem, description, criticality, metadata}, _from, state) do
    id = uuid_v4()
    assumption = %{
      id: id, subsystem: subsystem, description: description,
      criticality: criticality, verified: false,
      evidence: nil, verifier: nil,
      metadata: metadata,
      registered_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {id, assumption})
    {:reply, {:ok, id}, %{state | total_assumptions: state.total_assumptions + 1}}
  end

  @impl true
  def handle_cast({:verify, id, evidence, verifier}, state) do
    case :ets.lookup(@table_name, id) do
      [{^id, entry}] ->
        :ets.insert(@table_name, {id, %{entry | verified: true, evidence: evidence, verifier: verifier}})
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
