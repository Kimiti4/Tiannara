defmodule Tiannara.CRAV.EventBusAudit do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 6 — Event Bus Audit.

  Audits event publish/subscribe per subsystem by scanning telemetry handlers,
  abstract code for telemetry.execute calls, NATS subscriptions, and
  Phoenix.PubSub subscriptions.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :event_bus, :audited]

  @subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime,
    :observatory, :sentinel
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

  @expected_subscriptions %{
    rea: [[:tiannara, :event, :emitted], [:tiannara, :subsystem, :heartbeat]],
    sentinel: [[:tiannara, :cis, :immune_action], [:tiannara, :cis, :collapse_forecast]],
    observatory: [[:observatory, :event, :ingested], [:observatory, :boot, :phase_start]],
    cis: [[:tiannara, :cis, :immune_action], [:tiannara, :cis, :state_change]],
    msg: [[:tiannara, :msg, :dispatched], [:tiannara, :msg, :received]],
    omce: [[:tiannara, :omce, :metric_emitted], [:tiannara, :omce, :anomaly]],
    ctl: [[:tiannara, :ctl, :command_issued], [:tiannara, :ctl, :feedback]],
    oed: [[:tiannara, :oed, :detection], [:tiannara, :oed, :calibration]],
    asc: [[:tiannara, :asc, :alignment_check], [:tiannara, :asc, :drift]],
    knowledge_graph: [[:tiannara, :kg, :node_added], [:tiannara, :kg, :edge_added]],
    civilization_runtime: [[:tiannara, :civ, :state_change], [:tiannara, :civ, :event]]
  }

  @known_pubsub_topics %{
    rea: "tiannara:rea",
    sentinel: "tiannara:sentinel",
    observatory: "tiannara:observatory",
    cis: "tiannara:cis",
    msg: "tiannara:msg"
  }

  @spec audit() :: {:ok, [map()]} | {:error, term()}
  def audit do
    try do
      handlers = safe_list_handlers()
      all_subscribed = collect_all_subscribed_events(handlers)

      entries =
        @subsystems
        |> Enum.uniq()
        |> Enum.map(fn subsystem ->
          mods = Map.get(@subsystem_modules, subsystem, [])
          published = collect_published(mods)
          subscribed = collect_subscribed(mods, handlers, subsystem)
          expected = Map.get(@expected_subscriptions, subsystem, [])
          missing = Enum.filter(expected, fn ev -> ev not in subscribed end)
          orphaned = Enum.filter(published, fn ev -> not MapSet.member?(all_subscribed, ev) end)

          %{
            name: subsystem,
            publishes: Enum.map(published, fn ev -> {ev, count_handler_matches(handlers, ev)} end),
            subscribes: Enum.map(subscribed, fn ev -> {ev, count_handler_matches(handlers, ev)} end),
            missing_expected: missing,
            orphaned_events: orphaned,
            total_published: length(published),
            total_subscribed: length(subscribed)
          }
        end)

      measurements = %{
        total_subsystems: length(entries),
        total_published: Enum.sum(Enum.map(entries, & &1.total_published)),
        total_subscribed: Enum.sum(Enum.map(entries, & &1.total_subscribed)),
        missing_count: Enum.sum(Enum.map(entries, fn e -> length(e.missing_expected) end)),
        orphaned_count: Enum.sum(Enum.map(entries, fn e -> length(e.orphaned_events) end))
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:event_bus_audit_failed, err}}
    catch
      kind, reason -> {:error, {:event_bus_audit_crashed, kind, reason}}
    end
  end

  @spec missing_events() :: {:ok, [{atom(), [atom()]}]} | {:error, term()}
  def missing_events do
    case audit() do
      {:ok, entries} ->
        missing =
          entries
          |> Enum.filter(fn e -> e.missing_expected != [] end)
          |> Enum.map(fn e -> {e.name, e.missing_expected} end)

        {:ok, missing}

      err ->
        err
    end
  end

  @spec orphaned_events() :: {:ok, [{atom(), [atom()]}]} | {:error, term()}
  def orphaned_events do
    case audit() do
      {:ok, entries} ->
        orphaned =
          entries
          |> Enum.filter(fn e -> e.orphaned_events != [] end)
          |> Enum.map(fn e -> {e.name, e.orphaned_events} end)

        {:ok, orphaned}

      err ->
        err
    end
  end

  @spec event_bus_report() :: {:ok, String.t()} | {:error, term()}
  def event_bus_report do
    case audit() do
      {:ok, entries} ->
        now = DateTime.utc_now()
        total_pub = Enum.sum(Enum.map(entries, & &1.total_published))
        total_sub = Enum.sum(Enum.map(entries, & &1.total_subscribed))
        total_missing = Enum.sum(Enum.map(entries, fn e -> length(e.missing_expected) end))
        total_orphaned = Enum.sum(Enum.map(entries, fn e -> length(e.orphaned_events) end))

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV EVENT BUS AUDIT — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Subsystems: #{length(entries)}  |  Published: #{total_pub}  |  Subscribed: #{total_sub}",
            "  Missing Expected: #{total_missing}  |  Orphaned: #{total_orphaned}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.flat_map(entries, fn e ->
              name_str = e.name |> Atom.to_string() |> String.upcase() |> String.pad_trailing(24)

              header = "  #{name_str} pub=#{e.total_published} sub=#{e.total_subscribed}"

              missing_lines =
                if e.missing_expected != [] do
                  ["    MISSING: " <> Enum.map_join(e.missing_expected, ", ", &inspect/1)]
                else
                  []
                end

              orphaned_lines =
                if e.orphaned_events != [] do
                  ["    ORPHANED: " <> Enum.map_join(e.orphaned_events, ", ", &inspect/1)]
                else
                  []
                end

              [header] ++ missing_lines ++ orphaned_lines
            end) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
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

  defp collect_all_subscribed_events(handlers) do
    handlers
    |> Enum.map(fn h -> Map.get(h, :event_name, []) end)
    |> Enum.reject(&(&1 == []))
    |> MapSet.new()
  end

  defp collect_published(mods) do
    mods
    |> Enum.flat_map(fn mod ->
      if Code.ensure_loaded?(mod) do
        extract_telemetry_events(mod)
      else
        []
      end
    end)
    |> Enum.uniq()
  end

  defp collect_subscribed(mods, handlers, subsystem) do
    telemetry_subs = collect_telemetry_subscriptions(mods, handlers)
    pubsub_subs = collect_pubsub_subscriptions(subsystem)
    nats_subs = collect_nats_subscriptions(subsystem)

    (telemetry_subs ++ pubsub_subs ++ nats_subs)
    |> Enum.uniq()
  end

  defp collect_telemetry_subscriptions(mods, handlers) do
    mod_set =
      mods
      |> Enum.filter(&Code.ensure_loaded?/1)
      |> MapSet.new()

    handlers
    |> Enum.filter(fn handler ->
      case Map.get(handler, :id) do
        {mod, _} when is_atom(mod) -> MapSet.member?(mod_set, mod)
        mod when is_atom(mod) -> MapSet.member?(mod_set, mod)
        _ -> false
      end
    end)
    |> Enum.map(fn h -> Map.get(h, :event_name, []) end)
    |> Enum.reject(&(&1 == []))
  end

  defp collect_pubsub_subscriptions(subsystem) do
    topic = Map.get(@known_pubsub_topics, subsystem)

    if topic do
      try do
        if Code.ensure_loaded?(Phoenix.PubSub) do
          pubsub_name = find_pubsub_name()

          case pubsub_name do
            nil ->
              []

            name ->
              if function_exported?(Phoenix.PubSub, :direct_pids, 2) do
                pids = apply(Phoenix.PubSub, :direct_pids, [name, topic])

                if is_list(pids) and pids != [] do
                  [[:tiannara, :pubsub, subsystem]]
                else
                  []
                end
              else
                []
              end
          end
        else
          []
        end
      rescue
        _ -> []
      catch
        _, _ -> []
      end
    else
      []
    end
  end

  defp collect_nats_subscriptions(subsystem) do
    try do
      if Code.ensure_loaded?(Tiannara.NATS) do
        if function_exported?(Tiannara.NATS, :subscriptions, 0) do
          subs = apply(Tiannara.NATS, :subscriptions, [])

          if is_list(subs) do
            matching =
              Enum.filter(subs, fn sub ->
                case sub do
                  %{subject: s} when is_binary(s) ->
                    String.contains?(s, Atom.to_string(subsystem))

                  s when is_binary(s) ->
                    String.contains?(s, Atom.to_string(subsystem))

                  _ ->
                    false
                end
              end)

            if matching != [] do
              [[:tiannara, :nats, subsystem]]
            else
              []
            end
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
    catch
      _, _ -> []
    end
  end

  defp find_pubsub_name do
    cond do
      Process.whereis(Tiannara.PubSub) -> Tiannara.PubSub
      Process.whereis(TiannaraWeb.Endpoint) -> TiannaraWeb.Endpoint
      true -> nil
    end
  end

  defp extract_telemetry_events(mod) do
    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          forms
          |> Enum.flat_map(&extract_execute_events/1)
          |> Enum.uniq()

        _ ->
          []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp extract_execute_events({:function, _, _, _, clauses}) do
    clauses
    |> Enum.flat_map(&extract_execute_from_expr/1)
  end

  defp extract_execute_events(_), do: []

  defp extract_execute_from_expr(tuple) when is_tuple(tuple) do
    cond do
      tuple_size(tuple) >= 3 and elem(tuple, 0) == :call ->
        fn_part = elem(tuple, 2)

        case fn_part do
          {:remote, _, {:atom, _, :telemetry}, {:atom, _, :execute}} ->
            args = elem(tuple, 3)

            case args do
              [{:list, _, elements} | _] ->
                event =
                  elements
                  |> Enum.map(fn
                    {:atom, _, val} -> val
                    _ -> nil
                  end)
                  |> Enum.reject(&is_nil/1)

                if event != [], do: [event], else: []

              _ ->
                []
            end

          _ ->
            tuple
            |> Tuple.to_list()
            |> Enum.flat_map(&extract_execute_from_expr/1)
        end

      true ->
        tuple
        |> Tuple.to_list()
        |> Enum.flat_map(&extract_execute_from_expr/1)
    end
  end

  defp extract_execute_from_expr(list) when is_list(list) do
    Enum.flat_map(list, &extract_execute_from_expr/1)
  end

  defp extract_execute_from_expr(_), do: []

  defp count_handler_matches(handlers, event_name) when is_list(event_name) do
    Enum.count(handlers, fn h -> Map.get(h, :event_name) == event_name end)
  end

  defp count_handler_matches(_, _), do: 0
end
