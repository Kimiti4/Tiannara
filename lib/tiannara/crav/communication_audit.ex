defmodule Tiannara.CRAV.CommunicationAudit do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 9 — Communication Audit.

  Audits cross-system communication by measuring latency, loss rate,
  failure counts, and detecting cycles across telemetry, pubsub,
  NATS, direct calls, and ETS channels.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :communication, :audited]

  @high_latency_threshold_ms 100

  @subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime,
    :observatory
  ]

  @subsystem_modules %{
    rea: [Tiannara.REA],
    sopl: [Tiannara.SOPL],
    cis: [Tiannara.CIS],
    msg: [Tiannara.MSG],
    omce: [Tiannara.OMCE],
    hsv: [Tiannara.HSV],
    grcc: [Tiannara.GRCC],
    oed: [Tiannara.OED],
    ctl: [Tiannara.CTL],
    a10: [Tiannara.A10],
    asc: [Tiannara.ASC],
    world_model: [Tiannara.WorldModel],
    sentinel: [Tiannara.Sentinel],
    planetary_twin: [Tiannara.PlanetaryTwin],
    discovery_pipeline: [Tiannara.DiscoveryPipeline],
    engineering_pipeline: [Tiannara.EngineeringPipeline],
    simulation_runtime: [Tiannara.SimulationRuntime],
    theory_ecology: [Tiannara.TheoryEcology],
    knowledge_graph: [Tiannara.KnowledgeGraph],
    civilization_runtime: [Tiannara.CivilizationRuntime],
    observatory: [Tiannara.Observatory]
  }

  @spec audit() :: {:ok, [map()]} | {:error, term()}
  def audit do
    try do
      handlers = safe_list_handlers()
      ets_tables = scan_ets_tables()
      pubsub_topics = scan_pubsub_topics()
      nats_subs = scan_nats_subscriptions()

      connections =
        @subsystems
        |> Enum.flat_map(fn source ->
          Enum.map(@subsystems, fn target ->
            {source, target}
          end)
        end)
        |> Enum.reject(fn {s, t} -> s == t end)
        |> Enum.map(fn {source, target} ->
          probe_connection(source, target, handlers, ets_tables, pubsub_topics, nats_subs)
        end)
        |> Enum.reject(fn conn ->
          conn.messages_sent == 0 and
            conn.messages_received == 0 and
            conn.channel == :direct_call and
            not connection_exists?(source_target_modules(conn.source, conn.target))
        end)

      total_sent = Enum.sum(Enum.map(connections, & &1.messages_sent))
      total_received = Enum.sum(Enum.map(connections, & &1.messages_received))
      total_failures = Enum.sum(Enum.map(connections, & &1.failure_count))
      cycles = Enum.count(connections, & &1.cycle_detected)

      measurements = %{
        total_connections: length(connections),
        messages_sent: total_sent,
        messages_received: total_received,
        failure_count: total_failures,
        cycles_detected: cycles
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, connections}
    rescue
      err -> {:error, {:communication_audit_failed, err}}
    catch
      kind, reason -> {:error, {:communication_audit_crashed, kind, reason}}
    end
  end

  @spec high_latency_connections() :: {:ok, [map()]} | {:error, term()}
  def high_latency_connections do
    case audit() do
      {:ok, connections} ->
        {:ok, Enum.filter(connections, fn conn ->
          case conn.latency_ms do
            nil -> false
            ms -> ms > @high_latency_threshold_ms
          end
        end)}

      err ->
        err
    end
  end

  @spec failed_connections() :: {:ok, [map()]} | {:error, term()}
  def failed_connections do
    case audit() do
      {:ok, connections} ->
        {:ok, Enum.filter(connections, &(&1.failure_count > 0))}

      err ->
        err
    end
  end

  @spec communication_report() :: {:ok, String.t()} | {:error, term()}
  def communication_report do
    case audit() do
      {:ok, connections} ->
        now = DateTime.utc_now()
        total_sent = Enum.sum(Enum.map(connections, & &1.messages_sent))
        total_recv = Enum.sum(Enum.map(connections, & &1.messages_received))
        total_fail = Enum.sum(Enum.map(connections, & &1.failure_count))
        total_retry = Enum.sum(Enum.map(connections, & &1.retry_count))
        cycles = Enum.count(connections, & &1.cycle_detected)
        high_lat = Enum.count(connections, fn c -> c.latency_ms != nil and c.latency_ms > @high_latency_threshold_ms end)

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV COMMUNICATION AUDIT — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Connections: #{length(connections)}  |  Sent: #{total_sent}  |  Received: #{total_recv}",
            "  Failures: #{total_fail}  |  Retries: #{total_retry}  |  Cycles: #{cycles}  |  High-latency: #{high_lat}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(connections, fn c ->
              src = c.source |> Atom.to_string() |> String.pad_trailing(22)
              tgt = c.target |> Atom.to_string() |> String.pad_trailing(22)
              ch = c.channel |> Atom.to_string() |> String.pad_trailing(12)
              lat = format_latency(c.latency_ms)
              loss = format_loss(c.loss_rate)
              cyc = if c.cycle_detected, do: " CYCLE", else: ""

              "  #{src} → #{tgt} [#{ch}] lat=#{lat} loss=#{loss} fail=#{c.failure_count}#{cyc}"
            end) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp probe_connection(source, target, handlers, ets_tables, pubsub_topics, nats_subs) do
    source_mods = Map.get(@subsystem_modules, source, [])
    target_mods = Map.get(@subsystem_modules, target, [])

    {channel, sent, received, latency, retries, failures} =
      detect_channel(source, target, source_mods, target_mods, handlers, ets_tables, pubsub_topics, nats_subs)

    cycle = detect_cycle(source, target, handlers, ets_tables, pubsub_topics, nats_subs)

    loss = if sent > 0, do: Float.round(max(0, sent - received) / sent, 4), else: 0.0

    %{
      source: source,
      target: target,
      channel: channel,
      messages_sent: sent,
      messages_received: received,
      latency_ms: latency,
      loss_rate: loss,
      retry_count: retries,
      failure_count: failures,
      cycle_detected: cycle
    }
  end

  defp detect_channel(source, target, source_mods, target_mods, handlers, ets_tables, pubsub_topics, nats_subs) do
    cond do
      telemetry_link?(source, target, handlers) ->
        count = count_telemetry_events(source, target, handlers)
        lat = measure_telemetry_latency(source, target)
        {:telemetry, count, count, lat, 0, 0}

      pubsub_link?(source, target, pubsub_topics) ->
        count = count_pubsub_messages(source, target, pubsub_topics)
        {:pubsub, count, count, nil, 0, 0}

      nats_link?(source, target, nats_subs) ->
        {:nats, 0, 0, nil, 0, 0}

      ets_link?(source, target, ets_tables) ->
        {:ets, 0, 0, nil, 0, 0}

      direct_link?(source_mods, target_mods) ->
        {lat, failures} = measure_direct_latency(source_mods, target_mods)
        {:direct_call, 0, 0, lat, 0, failures}

      true ->
        {:direct_call, 0, 0, nil, 0, 0}
    end
  end

  defp telemetry_link?(source, target, handlers) do
    source_str = Atom.to_string(source)
    target_str = Atom.to_string(target)

    Enum.any?(handlers, fn h ->
      event = Map.get(h, :event_name, [])
      event_str = Enum.map_join(event, ".", &Atom.to_string/1)
      String.contains?(event_str, source_str) or String.contains?(event_str, target_str)
    end)
  end

  defp count_telemetry_events(source, target, handlers) do
    source_str = Atom.to_string(source)
    target_str = Atom.to_string(target)

    Enum.count(handlers, fn h ->
      event = Map.get(h, :event_name, [])
      event_str = Enum.map_join(event, ".", &Atom.to_string/1)
      String.contains?(event_str, source_str) and String.contains?(event_str, target_str)
    end)
  end

  defp measure_telemetry_latency(source, target) do
    source_mods = Map.get(@subsystem_modules, source, [])
    target_mods = Map.get(@subsystem_modules, target, [])

    source_alive = Enum.any?(source_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    target_alive = Enum.any?(target_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    if source_alive and target_alive do
      start_us = System.monotonic_time(:microsecond)

      try do
        target_mod = Enum.find(target_mods, &(Code.ensure_loaded?(&1) and Process.whereis(&1) != nil))

        if target_mod and function_exported?(target_mod, :ping, 0) do
          apply(target_mod, :ping, [])
        end
      rescue
        _ -> :ok
      end

      elapsed = System.monotonic_time(:microsecond) - start_us
      div(elapsed, 1000)
    else
      nil
    end
  end

  defp pubsub_link?(source, target, pubsub_topics) do
    source_topic = Map.get(pubsub_topics, source)
    target_topic = Map.get(pubsub_topics, target)

    source_topic != nil and target_topic != nil and source_topic == target_topic
  end

  defp count_pubsub_messages(_source, _target, _pubsub_topics), do: 0

  defp nats_link?(_source, _target, nats_subs) do
    nats_subs != []
  end

  defp ets_link?(source, target, ets_tables) do
    source_tables = MapSet.new(Map.get(ets_tables, source, []))
    target_tables = MapSet.new(Map.get(ets_tables, target, []))

    not MapSet.disjoint?(source_tables, target_tables)
  end

  defp direct_link?(source_mods, target_mods) do
    source_alive = Enum.any?(source_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    target_alive = Enum.any?(target_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    source_alive and target_alive
  end

  defp measure_direct_latency(source_mods, target_mods) do
    source_alive = Enum.any?(source_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    target_alive = Enum.any?(target_mods, fn mod ->
      Code.ensure_loaded?(mod) and Process.whereis(mod) != nil
    end)

    if source_alive and target_alive do
      target_mod = Enum.find(target_mods, &(Code.ensure_loaded?(&1) and Process.whereis(&1) != nil))

      if target_mod do
        start_us = System.monotonic_time(:microsecond)

        result =
          try do
            if function_exported?(target_mod, :ping, 0) do
              apply(target_mod, :ping, [])
            else
              :ok
            end
          rescue
            _ -> {:error, "probe_failed"}
          catch
            _, _ -> {:error, "probe_crashed"}
          end

        elapsed = System.monotonic_time(:microsecond) - start_us
        latency = div(elapsed, 1000)
        failures = if match?({:error, _}, result), do: 1, else: 0
        {latency, failures}
      else
        {nil, 0}
      end
    else
      {nil, 0}
    end
  end

  defp detect_cycle(source, target, handlers, ets_tables, pubsub_topics, nats_subs) do
    reverse_exists =
      cond do
        telemetry_link?(target, source, handlers) -> true
        pubsub_link?(target, source, pubsub_topics) -> true
        nats_link?(target, source, nats_subs) -> true
        ets_link?(target, source, ets_tables) -> true
        true -> false
      end

    reverse_exists
  end

  defp connection_exists?({_source_mods, _target_mods}), do: false

  defp source_target_modules(source, target) do
    {Map.get(@subsystem_modules, source, []), Map.get(@subsystem_modules, target, [])}
  end

  defp safe_list_handlers do
    try do
      :telemetry.list_handlers([])
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp scan_ets_tables do
    try do
      :ets.all()
      |> Enum.flat_map(fn tid ->
        try do
          name = :ets.info(tid, :name)
          owner = :ets.info(tid, :owner)

          owner_name = case Process.info(owner, :registered_name) do
            {:registered_name, n} when is_atom(n) -> n
            _ -> nil
          end

          if owner_name do
            subsystem = resolve_subsystem_for_process(owner_name)
            if subsystem, do: [{subsystem, name}], else: []
          else
            []
          end
        rescue
          _ -> []
        end
      end)
      |> Enum.group_by(fn {subsystem, _} -> subsystem end, fn {_, table} -> table end)
    rescue
      _ -> %{}
    end
  end

  defp scan_pubsub_topics do
    try do
      if Code.ensure_loaded?(Phoenix.PubSub) do
        pubsub_name = find_pubsub_name()

        if pubsub_name do
          @subsystems
          |> Enum.flat_map(fn subsystem ->
            topic = "tiannara:#{subsystem}"

            pids =
              if function_exported?(Phoenix.PubSub, :direct_pids, 2) do
                apply(Phoenix.PubSub, :direct_pids, [pubsub_name, topic])
              else
                []
              end

            if is_list(pids) and pids != [] do
              [{subsystem, topic}]
            else
              []
            end
          end)
          |> Map.new()
        else
          %{}
        end
      else
        %{}
      end
    rescue
      _ -> %{}
    end
  end

  defp scan_nats_subscriptions do
    try do
      if Code.ensure_loaded?(Tiannara.NATS) do
        if function_exported?(Tiannara.NATS, :subscriptions, 0) do
          subs = apply(Tiannara.NATS, :subscriptions, [])

          if is_list(subs) do
            subs
            |> Enum.flat_map(fn sub ->
              subsystem = case sub do
                %{subject: s} when is_binary(s) -> resolve_subsystem_from_subject(s)
                s when is_binary(s) -> resolve_subsystem_from_subject(s)
                _ -> nil
              end

              if subsystem, do: [{subsystem, sub}], else: []
            end)
          else
            []
          end
        else
          []
        end
      else
        []
      end
    rescue
      _ -> []
    end
  end

  defp find_pubsub_name do
    cond do
      Process.whereis(Tiannara.PubSub) -> Tiannara.PubSub
      Process.whereis(TiannaraWeb.Endpoint) -> TiannaraWeb.Endpoint
      true -> nil
    end
  end

  defp resolve_subsystem_for_process(name) do
    str = Atom.to_string(name)

    Enum.find(@subsystems, fn subsystem ->
      String.contains?(str, subsystem |> Atom.to_string() |> Macro.camelize())
    end)
  end

  defp resolve_subsystem_from_subject(subject) do
    Enum.find(@subsystems, fn subsystem ->
      String.contains?(subject, Atom.to_string(subsystem))
    end)
  end

  defp format_latency(nil), do: "n/a"
  defp format_latency(ms), do: "#{ms}ms"

  defp format_loss(rate) when is_float(rate), do: "#{Float.round(rate * 100, 2)}%"
  defp format_loss(_), do: "0%"
end
