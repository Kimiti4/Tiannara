defmodule Tiannara.Operations.CampaignIntegration do
  use GenServer
  require Logger

  alias Tiannara.World.UnifiedWorldModel

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route_result(campaign_id, result) do
    GenServer.cast(__MODULE__, {:route, campaign_id, result})
  end

  def topology, do: GenServer.call(__MODULE__, :topology)
  def feedback_history, do: GenServer.call(__MODULE__, :feedback_history)

  @impl true
  def init(_opts) do
    {:ok, %{
      routes: build_routing_table(),
      feedback_history: [],
      integrations_completed: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast({:route, campaign_id, result}, state) do
    new_state = do_route(campaign_id, result, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:topology, _from, state) do
    {:reply, state.routes, state}
  end

  @impl true
  def handle_call(:feedback_history, _from, state) do
    {:reply, state.feedback_history, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp build_routing_table do
    %{
      phase6: %{
        name: "Research Civilization",
        outputs_to: [:phase7, :world_model],
        receives_from: [:phase5]
      },
      phase7: %{
        name: "Meta-Science",
        outputs_to: [:phase8a, :phase5],
        receives_from: [:phase6]
      },
      phase8a: %{
        name: "Autonomous Engineering",
        outputs_to: [:phase8b, :world_model],
        receives_from: [:phase7]
      },
      phase8b: %{
        name: "Reality Anchoring",
        outputs_to: [:phase9, :world_model],
        receives_from: [:phase8a]
      },
      phase9: %{
        name: "Autonomous Guild",
        outputs_to: [:phase10, :world_model],
        receives_from: [:phase8b]
      },
      phase10: %{
        name: "Product Delivery",
        outputs_to: [:phase5, :world_model],
        receives_from: [:phase9]
      }
    }
  end

  defp do_route(campaign_id, result, state) do
    start = System.monotonic_time(:millisecond)
    route = Map.get(state.routes, campaign_id)

    if route == nil do
      Logger.warning("CampaignIntegration: Unknown campaign #{campaign_id}")
      state
    else
      Enum.each(route.outputs_to, fn target ->
        case target do
          :world_model -> update_world_model(campaign_id, result)
          downstream_phase -> feed_downstream(downstream_phase, campaign_id, result)
        end
      end)

      feedback_entry =
        if :phase5 in route.outputs_to do
          entry = %{
            from: campaign_id,
            to: :phase5,
            result_summary: summarize_result(result),
            at: DateTime.utc_now()
          }
          Logger.info("CampaignIntegration: Feedback loop closed — #{campaign_id} → Phase 5")
          entry
        else
          nil
        end

      dur = System.monotonic_time(:millisecond) - start

      :telemetry.execute([:tiannara, :campaign, :route], %{duration_ms: dur}, %{from: campaign_id, ok: true})

      if feedback_entry != nil do
        :telemetry.execute([:tiannara, :campaign, :feedback_closed], %{count: 1}, %{from: campaign_id})
      end

      %{state |
        integrations_completed: state.integrations_completed + 1,
        feedback_history: if(feedback_entry, do: [feedback_entry | state.feedback_history] |> Enum.take(500), else: state.feedback_history)
      }
    end
  end

  defp update_world_model(campaign_id, result) do
    try do
      entity_id = "campaign_output_#{campaign_id}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      spec = %{
        id: entity_id,
        domain: :campaign_output,
        type: :knowledge,
        subtype: :information,
        attributes: %{
          source_campaign: campaign_id,
          result: summarize_result(result),
          produced_at: DateTime.utc_now()
        },
        confidence: 0.7,
        uncertainty: 0.3,
        provenance: %{
          origin: :campaign_integration,
          produced_by: campaign_id,
          produced_at: DateTime.utc_now()
        },
        owner_subsystem: :campaign_integration,
        version: 1,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        status: :active
      }
      UnifiedWorldModel.create_entity(spec)
      Logger.debug("CampaignIntegration: World Model updated from #{campaign_id}")
    rescue
      e -> Logger.warning("CampaignIntegration: World Model update failed: #{inspect(e)}")
    end
  end

  defp feed_downstream(downstream_phase, campaign_id, result) do
    try do
      Tiannara.CEL.Services.EventBus.Safe.publish(
        "campaign.#{downstream_phase}.input",
        %{
          source_campaign: campaign_id,
          result: summarize_result(result),
          timestamp: DateTime.utc_now()
        }
      )
      Logger.debug("CampaignIntegration: Fed #{campaign_id} → #{downstream_phase}")
    rescue
      _ -> :ok
    end
  end

  defp summarize_result(result) when is_map(result) do
    Map.take(result, [:status, :result, :discoveries, :principles, :designs, :forecasts, :metrics, :strategy, :validated, :outcomes, :hypothesis_types, :cycle_time_ms])
  end

  defp summarize_result(result), do: %{raw: inspect(result, limit: 5)}
end
