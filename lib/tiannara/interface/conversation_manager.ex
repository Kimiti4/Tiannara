defmodule Tiannara.Interface.ConversationManager do
  @moduledoc """
  Conversation Manager — manages dialogue state, context, and turn-taking.
  Tracks active conversations between Tiannara and human operators,
  maintaining context, history, and state across multiple exchanges.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec create(atom(), map(), atom()) :: {:ok, binary()}
  def create(topic, context, initiated_by) do
    GenServer.call(__MODULE__, {:create, topic, context, initiated_by})
  end

  @spec handle_input(binary(), String.t()) :: {:ok, map()} | {:error, term()}
  def handle_input(conversation_id, message) do
    GenServer.call(__MODULE__, {:handle_input, conversation_id, message})
  end

  @spec append_response(binary(), map()) :: :ok
  def append_response(conversation_id, response) do
    GenServer.cast(__MODULE__, {:append_response, conversation_id, response})
  end

  @spec resolve(binary()) :: :ok
  def resolve(conversation_id) do
    GenServer.cast(__MODULE__, {:resolve, conversation_id})
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
    {:ok, %{conversations: %{}, total_created: 0, total_resolved: 0}}
  end

  @impl true
  def handle_call({:create, topic, context, initiated_by}, _from, state) do
    id = Types.new_id()
    conversation = %{id: id, topic: topic, status: :initiated, context: context, history: [], initiated_by: initiated_by, participant: nil, created_at: DateTime.utc_now(), last_activity_at: DateTime.utc_now(), turn_count: 0}
    conversations = Map.put(state.conversations, id, conversation)

    :telemetry.execute([:tiannara, :interface, :conversation_created], %{count: 1}, %{topic: topic, initiated_by: initiated_by})

    {:reply, {:ok, id}, %{state | conversations: conversations, total_created: state.total_created + 1}}
  end

  @impl true
  def handle_call({:handle_input, conversation_id, message}, _from, state) do
    case Map.get(state.conversations, conversation_id) do
      nil -> {:reply, {:error, :conversation_not_found}, state}
      conversation ->
        human_turn = %{role: :human, content: message, timestamp: DateTime.utc_now()}
        response = generate_response(conversation, message)
        tiannara_turn = %{role: :tiannara, content: response.content, evidence: response.evidence, confidence: response.confidence, timestamp: DateTime.utc_now()}
        updated = %{conversation | history: conversation.history ++ [human_turn, tiannara_turn], status: :active, last_activity_at: DateTime.utc_now(), turn_count: conversation.turn_count + 2}
        conversations = Map.put(state.conversations, conversation_id, updated)
        {:reply, {:ok, tiannara_turn}, %{state | conversations: conversations}}
    end
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    active = state.conversations |> Map.values() |> Enum.count(fn c -> c.status in [:initiated, :active, :waiting] end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_conversations: map_size(state.conversations), total_created: state.total_created, total_resolved: state.total_resolved, by_status: state.conversations |> Map.values() |> Enum.frequencies_by(& &1.status)}, state}
  end

  @impl true
  def handle_cast({:append_response, conversation_id, response}, state) do
    case Map.get(state.conversations, conversation_id) do
      nil -> {:noreply, state}
      conversation ->
        turn = %{role: :tiannara, content: response[:content], evidence: response[:evidence], confidence: response[:confidence], timestamp: DateTime.utc_now()}
        updated = %{conversation | history: conversation.history ++ [turn], last_activity_at: DateTime.utc_now(), turn_count: conversation.turn_count + 1}
        {:noreply, %{state | conversations: Map.put(state.conversations, conversation_id, updated)}}
    end
  end

  @impl true
  def handle_cast({:resolve, conversation_id}, state) do
    case Map.get(state.conversations, conversation_id) do
      nil -> {:noreply, state}
      conversation ->
        updated = %{conversation | status: :resolved, last_activity_at: DateTime.utc_now()}
        {:noreply, %{state | conversations: Map.put(state.conversations, conversation_id, updated), total_resolved: state.total_resolved + 1}}
    end
  end

  defp generate_response(conversation, message) do
    %{content: "Acknowledged. Regarding #{conversation.topic}: I have recorded your input and will incorporate it into my analysis. Current evidence supports continued investigation.", evidence: conversation.context[:evidence] || [], confidence: conversation.context[:confidence] || 0.5}
  end
end
