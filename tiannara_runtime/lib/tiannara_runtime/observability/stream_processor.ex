defmodule TiannaraRuntime.Observability.StreamProcessor do
  @moduledoc """
  COGNITIVE OBSERVABILITY LAYER: Real-Time Stream Processor

  This is the missing bridge between NATS cognitive events and UI visualization.

  Subscribes to all critical cognitive event streams:
  - tiannara.cal.* : Coalition formation, arbitration, suppression
  - tiannara.cis.* : Entropy monitoring, interventions, quarantine
  - tiannara.system.* : Health pulses, failures, mode switches

  Transforms raw events into visual state mutations and broadcasts via Phoenix PubSub.

  Design Principle: Every cognitive event becomes a "visual state mutation" — not logs, not charts.
  """

  use GenServer
  require Logger

  # NATS subscription topics for cognitive observability
  @sub_topics [
    # Coalition Activity Layer
    "tiannara.cal.>",
    # Cognitive Immune System
    "tiannara.cis.>",
    # System-level events
    "tiannara.system.>"
  ]

  @default_nats_url "nats://localhost:4222"
  @default_reconnect_delay_ms 1_000
  @default_max_reconnect_delay_ms 60_000
  @default_local_buffer_size 1_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get current stream processor state (for debugging).
  """
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    config = Application.get_env(:tiannara_runtime, __MODULE__, [])

    nats_url =
      Keyword.get(
        opts,
        :nats_url,
        Keyword.get(config, :nats_url, System.get_env("NATS_URL", @default_nats_url))
      )

    state = %{
      gnat_pid: nil,
      subscriptions: [],
      event_count: 0,
      last_event_time: nil,
      viz_subscribers: 0,
      degraded_mode: false,
      local_buffer: [],
      max_local_buffer_size:
        Keyword.get(
          opts,
          :local_buffer_size,
          Keyword.get(config, :local_buffer_size, @default_local_buffer_size)
        ),
      nats_url: nats_url,
      reconnect_attempts: 0,
      reconnect_delay_ms:
        Keyword.get(
          opts,
          :reconnect_delay_ms,
          Keyword.get(config, :reconnect_delay_ms, @default_reconnect_delay_ms)
        ),
      max_reconnect_delay_ms:
        Keyword.get(
          opts,
          :max_reconnect_delay_ms,
          Keyword.get(config, :max_reconnect_delay_ms, @default_max_reconnect_delay_ms)
        )
    }

    # Initialize NATS connection
    case connect_nats(state.nats_url) do
      {:ok, gnat_pid} ->
        Logger.info("✅ Observability StreamProcessor connected to NATS")

        # Subscribe to all cognitive event topics
        subscriptions =
          Enum.map(@sub_topics, fn topic ->
            subscribe_to_topic(gnat_pid, topic)
          end)

        new_state = %{state | gnat_pid: gnat_pid, subscriptions: subscriptions}

        {:ok, new_state}

      {:error, reason} ->
        Logger.warning(
          "Observability StreamProcessor NATS unavailable: #{inspect(reason)}; entering degraded local-buffer mode"
        )

        {:ok, schedule_reconnect(%{state | degraded_mode: true})}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:msg, %{body: body, topic: topic}}, state) do
    # Process incoming NATS message
    processed_state = process_message(topic, body, state)
    {:noreply, processed_state}
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("🔄 Observability StreamProcessor attempting NATS reconnection...")

    case connect_nats(state.nats_url) do
      {:ok, gnat_pid} ->
        Logger.info("✅ NATS reconnected")

        # Re-subscribe to all topics
        subscriptions =
          Enum.map(@sub_topics, fn topic ->
            subscribe_to_topic(gnat_pid, topic)
          end)

        {:noreply,
         %{
           state
           | gnat_pid: gnat_pid,
             subscriptions: subscriptions,
             degraded_mode: false,
             reconnect_attempts: 0
         }}

      {:error, reason} ->
        Logger.warning("Observability StreamProcessor NATS reconnect failed: #{inspect(reason)}")

        {:noreply,
         schedule_reconnect(%{
           state
           | degraded_mode: true,
             reconnect_attempts: state.reconnect_attempts + 1
         })}
    end
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %{gnat_pid: pid} = state) do
    Logger.warning("Observability StreamProcessor NATS connection exited: #{inspect(reason)}")

    {:noreply,
     state
     |> Map.merge(%{
       gnat_pid: nil,
       subscriptions: [],
       degraded_mode: true,
       reconnect_attempts: state.reconnect_attempts + 1
     })
     |> schedule_reconnect()}
  end

  # Private Functions

  defp connect_nats(nats_url) do
    nats_url
    |> nats_connection_settings()
    |> Gnat.start_link()
  rescue
    exception ->
      {:error, exception}
  catch
    :exit, reason ->
      {:error, reason}
  end

  defp nats_connection_settings(nats_url) do
    uri = URI.parse(nats_url)
    scheme = uri.scheme || "nats"

    %{
      host: uri.host || "localhost",
      port: uri.port || 4222,
      tls: scheme in ["tls", "nats+tls"]
    }
  end

  defp subscribe_to_topic(gnat_pid, topic) do
    case Gnat.sub(gnat_pid, self(), topic) do
      {:ok, _subscription_id} ->
        Logger.info("📥 Observability subscribed to: #{topic}")
        topic

      {:error, reason} ->
        Logger.error("Failed to subscribe to #{topic}: #{inspect(reason)}")
        nil
    end
  end

  defp process_message(topic, body, state) do
    # Decode JSON payload
    data =
      case Jason.decode(body) do
        {:ok, decoded} -> decoded
        {:error, _} -> %{"raw" => body}
      end

    # Transform event into visual state mutation
    visual_event = transform_to_visual_event(topic, data)

    # Broadcast to visualization subscribers via Phoenix PubSub
    broadcast_visual_event(visual_event)

    # Update state
    new_state = %{
      state
      | event_count: state.event_count + 1,
        last_event_time: DateTime.utc_now()
    }

    Logger.debug(
      "🎨 Visual event broadcast: #{visual_event["layer"]}.#{visual_event["entity_type"]}"
    )

    new_state
  end

  defp transform_to_visual_event(topic, data) do
    # Extract layer from topic
    layer = extract_layer(topic)

    # Enrich with visual state based on event type
    enriched_data = enrich_visual_state(layer, data)

    # Build unified visualization model
    %{
      "timestamp" => DateTime.utc_now() |> DateTime.to_unix(),
      "layer" => layer,
      "entity_type" => Map.get(enriched_data, "entity_type", "unknown"),
      "entity_id" => Map.get(enriched_data, "entity_id", "unknown"),
      "metrics" => Map.get(enriched_data, "metrics", %{}),
      "state" => Map.get(enriched_data, "state", "active"),
      "position" => Map.get(enriched_data, "position", [0, 0, 0]),
      "visual_type" => Map.get(enriched_data, "visual_type", "generic_update"),
      "raw_event" => data
    }
  end

  defp extract_layer(topic) do
    case topic do
      "tiannara.cal." <> _ -> "cal"
      "tiannara.cis." <> _ -> "cis"
      "tiannara.system." <> _ -> "system"
      _ -> "unknown"
    end
  end

  defp enrich_visual_state("cal", data) do
    # CAL → Graph Space transformations
    case Map.get(data, "type", "") do
      "coalition.formed" ->
        Map.merge(data, %{
          "entity_type" => "coalition",
          "visual_type" => "node_create",
          "state" => "active"
        })

      "coalition.updated" ->
        Map.merge(data, %{
          "entity_type" => "coalition",
          "visual_type" => "node_morph",
          "state" => "active"
        })

      "coalition.arbitration" ->
        Map.merge(data, %{
          "entity_type" => "coalition",
          "visual_type" => "node_highlight",
          "state" => "arbitrating"
        })

      "coalition.suppressed" ->
        Map.merge(data, %{
          "entity_type" => "coalition",
          "visual_type" => "node_fade",
          "state" => "suppressed"
        })

      _ ->
        Map.merge(data, %{
          "entity_type" => "coalition",
          "visual_type" => "generic_update"
        })
    end
  end

  defp enrich_visual_state("cis", data) do
    # CIS → Field Space transformations
    case Map.get(data, "type", "") do
      "entropy.spike" ->
        Map.merge(data, %{
          "entity_type" => "field",
          "visual_type" => "heatwave_expansion",
          "state" => "high_entropy"
        })

      "entropy.damping" ->
        Map.merge(data, %{
          "entity_type" => "field",
          "visual_type" => "cooling_gradient",
          "state" => "stabilizing"
        })

      "intervention.issued" ->
        Map.merge(data, %{
          "entity_type" => "intervention",
          "visual_type" => "heatwave_damp",
          "state" => "active"
        })

      "quarantine.applied" ->
        Map.merge(data, %{
          "entity_type" => "field",
          "visual_type" => "region_isolate",
          "state" => "quarantined"
        })

      "recovery.wave" ->
        Map.merge(data, %{
          "entity_type" => "field",
          "visual_type" => "stabilization_wave",
          "state" => "recovering"
        })

      _ ->
        Map.merge(data, %{
          "entity_type" => "field",
          "visual_type" => "generic_update"
        })
    end
  end

  defp enrich_visual_state("system", data) do
    # System Events → Timeline Layer transformations
    case Map.get(data, "type", "") do
      "failure.alert" ->
        Map.merge(data, %{
          "entity_type" => "system",
          "visual_type" => "red_pulse",
          "state" => "critical"
        })

      "recovery.complete" ->
        Map.merge(data, %{
          "entity_type" => "system",
          "visual_type" => "green_rebound",
          "state" => "healthy"
        })

      "mode.switch" ->
        Map.merge(data, %{
          "entity_type" => "system",
          "visual_type" => "phase_shift",
          "state" => Map.get(data, "new_mode", "unknown")
        })

      "health.pulse" ->
        Map.merge(data, %{
          "entity_type" => "system",
          "visual_type" => "heartbeat",
          "state" => Map.get(data, "status", "unknown")
        })

      _ ->
        Map.merge(data, %{
          "entity_type" => "system",
          "visual_type" => "generic_update"
        })
    end
  end

  defp broadcast_visual_event(event) do
    # Broadcast to all visualization subscribers
    Phoenix.PubSub.broadcast(
      TiannaraRuntime.PubSub,
      "visualization",
      {:viz_event, event}
    )
  end

  defp schedule_reconnect(state) do
    delay =
      state.reconnect_delay_ms
      |> Kernel.*(:math.pow(2, state.reconnect_attempts))
      |> round()
      |> min(state.max_reconnect_delay_ms)

    Process.send_after(self(), :reconnect, delay)
    state
  end
end
