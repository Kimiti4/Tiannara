defmodule Tiannara.CEL.EventBus do
  use GenServer
  require Logger

  alias Tiannara.CEL.Models.CivilizationalEvent

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def ingest_event(raw_event, origin_subsystem) do
    GenServer.cast(__MODULE__, {:ingest, raw_event, origin_subsystem})
  end

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts) do
    Logger.info("CEL EventBus: Unified event system active.")
    {:ok, %{processed: 0}}
  end

  @impl true
  def handle_cast({:ingest, raw_event, origin}, state) do
    civ_event = normalize(raw_event, origin)

    priority = Tiannara.CEL.PriorityEngine.calculate_global_priority(civ_event)
    civ_event = %{civ_event | priority: priority}

    case Tiannara.CEL.CapabilityRegistry.get_delegation_target(civ_event.type) do
      {:ok, target_subsystem} ->
        route_to_subsystem(target_subsystem, civ_event)

      {:error, :no_capable_subsystem} ->
        Logger.warning("EventBus: No subsystem capable of handling #{civ_event.type}. Escalating.")
        escalate_to_executive(civ_event)
    end

    {:noreply, %{state | processed: state.processed + 1}}
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive_service_bus,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.9,
      human_oversight: 0.7,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end

  defp normalize(raw_event, origin) do
    %CivilizationalEvent{
      id: generate_id(),
      origin: origin,
      type: infer_event_type(raw_event),
      raw_payload: raw_event,
      evidence: Map.get(raw_event, :confidence, 0.5),
      confidence: Map.get(raw_event, :confidence, 0.5),
      urgency: Map.get(raw_event, :urgency, :medium),
      timestamp: DateTime.utc_now()
    }
  end

  defp infer_event_type(%Tiannara.Agency.Models.AgencyEvent{}), do: :investigate
  defp infer_event_type(%{__struct__: Tiannara.Sentinel.Activation.Event}), do: :detect
  defp infer_event_type(_), do: :generic

  defp route_to_subsystem(subsystem_id, _civ_event) do
    Logger.info("EventBus: Routing #{subsystem_id}")
  end

  defp escalate_to_executive(civ_event) do
    Tiannara.CEL.Executive.handle_escalation(civ_event)
  end

  defp generate_id, do: "civ_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
end
