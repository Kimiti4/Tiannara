defmodule Tiannara.Interface.CognitiveInterface do
  @moduledoc """
  Cognitive Interface — TIA-OMEGA-3

  The communication layer enabling Tiannara to initiate scientific dialogue
  with human operators. Transforms internal discoveries, anomalies, and
  research outcomes into structured, evidence-backed communications.
  """

  use Supervisor
  require Logger

  alias Tiannara.Interface.{ConversationManager, ProactiveNotifier, ScientificDialogue, DiscoveryPresenter, HumanCollaboration}

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    %{conversations: ConversationManager.status(), notifications: ProactiveNotifier.status(), dialogues: ScientificDialogue.status(), collaborations: HumanCollaboration.status()}
  end

  @spec health() :: map()
  def health do
    %{status: :healthy, active_conversations: ConversationManager.active_count(), pending_notifications: ProactiveNotifier.pending_count(), total_communications: ProactiveNotifier.total_sent(), active_collaborations: HumanCollaboration.active_count()}
  end

  @spec surface_discovery(map()) :: {:ok, binary()} | {:error, term()}
  def surface_discovery(discovery) do
    ProactiveNotifier.notify(discovery)
  end

  @spec initiate_dialogue(atom(), map()) :: {:ok, binary()}
  def initiate_dialogue(topic, context) do
    ScientificDialogue.initiate(topic, context)
  end

  @spec handle_human_input(binary(), String.t()) :: {:ok, map()} | {:error, term()}
  def handle_human_input(conversation_id, message) do
    ConversationManager.handle_input(conversation_id, message)
  end

  @spec pending_notifications() :: [map()]
  def pending_notifications do
    ProactiveNotifier.pending()
  end

  @impl true
  def init(opts) do
    Logger.info("[CognitiveInterface] Starting Cognitive Interface...")
    notification_rate_limit = Keyword.get(opts, :notification_rate_limit_per_hour, 10)

    children = [
      %{id: ConversationManager, start: {ConversationManager, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: DiscoveryPresenter, start: {DiscoveryPresenter, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ScientificDialogue, start: {ScientificDialogue, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: HumanCollaboration, start: {HumanCollaboration, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ProactiveNotifier, start: {ProactiveNotifier, :start_link, [[rate_limit_per_hour: notification_rate_limit]]}, restart: :permanent, shutdown: 5_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 30)
  end
end
