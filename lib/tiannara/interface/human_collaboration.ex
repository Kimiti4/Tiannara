defmodule Tiannara.Interface.HumanCollaboration do
  @moduledoc """
  Human Collaboration — manages collaborative workflows between Tiannara and operators.
  Supports structured collaboration patterns: inform, consult, approve, collaborate, escalate.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec request(:inform | :consult | :approve | :collaborate | :escalate, atom(), map(), String.t()) :: {:ok, binary()}
  def request(mode, topic, context, rationale) do
    GenServer.call(__MODULE__, {:request, mode, topic, context, rationale})
  end

  @spec respond(binary(), term()) :: :ok | {:error, :not_found}
  def respond(collaboration_id, response) do
    GenServer.call(__MODULE__, {:respond, collaboration_id, response})
  end

  @spec active() :: [map()]
  def active do
    GenServer.call(__MODULE__, :active)
  end

  @spec active_count() :: non_neg_integer()
  def active_count do
    GenServer.call(__MODULE__, :active_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{collaborations: %{}, total_requested: 0, total_resolved: 0, total_expired: 0}}
  end

  @impl true
  def handle_call({:request, mode, topic, context, rationale}, _from, state) do
    id = Types.new_id()
    collaboration = %{id: id, mode: mode, status: :pending, topic: topic, context: context, rationale: rationale, requested_at: DateTime.utc_now(), resolved_at: nil, human_response: nil, expires_at: compute_expiry(mode)}
    collaborations = Map.put(state.collaborations, id, collaboration)

    :telemetry.execute([:tiannara, :interface, :collaboration_requested], %{count: 1}, %{mode: mode, topic: topic})
    Logger.info("[HumanCollaboration] #{String.upcase(to_string(mode))} requested. Topic: #{topic} ID: #{id}")

    {:reply, {:ok, id}, %{state | collaborations: collaborations, total_requested: state.total_requested + 1}}
  end

  @impl true
  def handle_call({:respond, collaboration_id, response}, _from, state) do
    case Map.get(state.collaborations, collaboration_id) do
      nil -> {:reply, {:error, :not_found}, state}
      collaboration ->
        updated = %{collaboration | status: :resolved, human_response: response, resolved_at: DateTime.utc_now()}
        :telemetry.execute([:tiannara, :interface, :collaboration_resolved], %{count: 1}, %{mode: collaboration.mode, topic: collaboration.topic})
        {:reply, :ok, %{state | collaborations: Map.put(state.collaborations, collaboration_id, updated), total_resolved: state.total_resolved + 1}}
    end
  end

  @impl true
  def handle_call(:active, _from, state) do
    active = state.collaborations |> Map.values() |> Enum.filter(fn c -> c.status in [:pending, :active, :awaiting_human] end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    count = state.collaborations |> Map.values() |> Enum.count(fn c -> c.status in [:pending, :active, :awaiting_human] end)
    {:reply, count, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_requested: state.total_requested, total_resolved: state.total_resolved, total_expired: state.total_expired, active: Enum.count(state.collaborations, fn {_, c} -> c.status in [:pending, :active, :awaiting_human] end), by_mode: state.collaborations |> Map.values() |> Enum.frequencies_by(& &1.mode)}, state}
  end

  defp compute_expiry(:inform), do: nil
  defp compute_expiry(:consult), do: DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
  defp compute_expiry(:approve), do: DateTime.add(DateTime.utc_now(), 4 * 3600, :second)
  defp compute_expiry(:collaborate), do: DateTime.add(DateTime.utc_now(), 7 * 24 * 3600, :second)
  defp compute_expiry(:escalate), do: DateTime.add(DateTime.utc_now(), 1 * 3600, :second)
end
