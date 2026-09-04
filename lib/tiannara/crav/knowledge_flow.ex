defmodule Tiannara.CRAV.KnowledgeFlow do
  @moduledoc """
  Phase Ω+ CRAV Knowledge Flow — Deliverable 11.

  Tracks knowledge through the system pipeline stages, measuring
  throughput, bottlenecks, and artifact flow across the
  information-to-evolution continuum.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :knowledge, :flow]

  @stages [:information, :knowledge, :theory, :engineering, :runtime, :evolution]

  @stage_module_patterns %{
    information: ["Observatory", "DataIngestion", "Sensor", "Raw", "NDE"],
    knowledge: ["KnowledgeGraph", "KnowledgeBase", "SemanticMap", "Ontology"],
    theory: ["TheoryEcology", "Theory", "Hypothesis", "Model", "Cosmology"],
    engineering: ["EngineeringPipeline", "Simulation", "Stabilization", "Engineering"],
    runtime: ["Core", "Civilization", "Planetary", "WorldModel", "Runtime"],
    evolution: ["Evolution", "PhaseOmega", "CRAV", "DiscoveryPipeline", "REA"]
  }

  @spec flow() :: {:ok, [map()]} | {:error, term()}
  def flow do
    try do
      modules = discover_modules()
      handler_counts = count_telemetry_handlers()

      entries =
        @stages
        |> Enum.map(fn stage ->
          mods = filter_modules_for_stage(modules, stage)

          artifacts_produced = count_artifacts_produced(mods, handler_counts)
          artifacts_consumed = count_artifacts_consumed(mods, handler_counts)
          throughput = compute_throughput(artifacts_produced, artifacts_consumed)
          bottleneck = compute_bottleneck(artifacts_produced, artifacts_consumed)
          last_activity = find_last_activity(mods)

          %{
            stage: stage,
            modules: mods,
            artifacts_produced: artifacts_produced,
            artifacts_consumed: artifacts_consumed,
            throughput: throughput,
            bottleneck: bottleneck,
            last_activity: last_activity
          }
        end)

      measurements = %{
        stages: length(entries),
        bottlenecks: Enum.count(entries, & &1.bottleneck),
        total_throughput: entries |> Enum.map(& &1.throughput) |> Enum.sum()
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:knowledge_flow_failed, err}}
    catch
      kind, reason -> {:error, {:knowledge_flow_crashed, kind, reason}}
    end
  end

  @spec bottlenecks() :: {:ok, [map()]} | {:error, term()}
  def bottlenecks do
    case flow() do
      {:ok, entries} ->
        {:ok, Enum.filter(entries, & &1.bottleneck)}

      err ->
        err
    end
  end

  @spec knowledge_report() :: {:ok, String.t()} | {:error, term()}
  def knowledge_report do
    case flow() do
      {:ok, entries} ->
        now = DateTime.utc_now()
        total_stages = length(entries)
        bottleneck_count = Enum.count(entries, & &1.bottleneck)
        total_throughput = entries |> Enum.map(& &1.throughput) |> Enum.sum()

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV KNOWLEDGE FLOW — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Stages: #{total_stages}  |  Bottlenecks: #{bottleneck_count}  |  Total Throughput: #{Float.round(total_throughput, 2)}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(entries, fn e ->
              stage_str =
                e.stage
                |> Atom.to_string()
                |> String.upcase()
                |> String.pad_trailing(16)

              mod_count = length(e.modules)
              produced_str = to_string(e.artifacts_produced) |> String.pad_leading(6)
              consumed_str = to_string(e.artifacts_consumed) |> String.pad_leading(6)

              throughput_str =
                Float.round(e.throughput, 2)
                |> to_string()
                |> String.pad_leading(8)

              bottleneck_flag =
                if e.bottleneck, do: " [BOTTLENECK]", else: ""

              "  #{stage_str} modules=#{String.pad_leading(to_string(mod_count), 4)} produced=#{produced_str} consumed=#{consumed_str} throughput=#{throughput_str}#{bottleneck_flag}"
            end) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp discover_modules do
    case :application.get_key(:tiannara, :modules) do
      {:ok, modules} when is_list(modules) -> modules
      _ -> []
    end
  end

  defp filter_modules_for_stage(modules, stage) do
    patterns = Map.get(@stage_module_patterns, stage, [])

    Enum.filter(modules, fn mod ->
      mod_str = Atom.to_string(mod)
      Enum.any?(patterns, &String.contains?(mod_str, &1))
    end)
  end

  defp count_telemetry_handlers do
    try do
      :telemetry.list_handlers([])
      |> Enum.group_by(fn handler ->
        case Map.get(handler, :id) do
          {mod, _} when is_atom(mod) -> mod
          mod when is_atom(mod) -> mod
          _ -> nil
        end
      end)
      |> Enum.reject(fn {k, _} -> k == nil end)
      |> Enum.map(fn {mod, hs} -> {mod, length(hs)} end)
      |> Enum.into(%{})
    rescue
      _ -> %{}
    catch
      _, _ -> %{}
    end
  end

  defp count_artifacts_produced(mods, handler_counts) do
    mods
    |> Enum.map(fn mod ->
      handler_count = Map.get(handler_counts, mod, 0)
      ets_count = module_ets_size(mod)
      handler_count + ets_count
    end)
    |> Enum.sum()
  end

  defp count_artifacts_consumed(mods, handler_counts) do
    mods
    |> Enum.map(fn mod ->
      handler_count = Map.get(handler_counts, mod, 0)
      ets_count = module_ets_size(mod)
      handler_count + div(ets_count, 2)
    end)
    |> Enum.sum()
  end

  defp module_ets_size(mod) do
    short = module_short_name(mod)

    try do
      :ets.all()
      |> Enum.filter(fn tid ->
        try do
          name = :ets.info(tid, :name)
          name_str = Atom.to_string(name) |> String.downcase()
          String.contains?(name_str, short)
        rescue
          _ -> false
        end
      end)
      |> Enum.map(fn tid ->
        try do
          :ets.info(tid, :size)
        rescue
          _ -> 0
        end
      end)
      |> Enum.sum()
    rescue
      _ -> 0
    end
  end

  defp module_short_name(mod) do
    Atom.to_string(mod)
    |> String.replace("Elixir.", "")
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end

  defp compute_throughput(produced, consumed) do
    if produced > 0 do
      Float.round(min(consumed / produced, 1.0), 4)
    else
      0.0
    end
  end

  defp compute_bottleneck(produced, consumed) do
    cond do
      produced == 0 -> false
      consumed == 0 -> true
      produced > consumed * 3 -> true
      true -> false
    end
  end

  defp find_last_activity(mods) do
    try do
      if Code.ensure_loaded?(Tiannara.PhaseOmega.SubsystemRegistry) and
           Process.whereis(Tiannara.PhaseOmega.SubsystemRegistry) do
        records = Tiannara.PhaseOmega.SubsystemRegistry.all()

        mods
        |> Enum.flat_map(fn mod ->
          Enum.filter(records, &(&1.module == mod))
          |> Enum.map(&datetime_to_unix(&1.last_activity))
          |> Enum.reject(&is_nil/1)
        end)
        |> case do
          [] -> check_live_processes(mods)
          times -> Enum.max(times)
        end
      else
        check_live_processes(mods)
      end
    rescue
      _ -> check_live_processes(mods)
    catch
      _, _ -> check_live_processes(mods)
    end
  end

  defp check_live_processes(mods) do
    has_live =
      Enum.any?(mods, fn mod ->
        try do
          pid = Process.whereis(mod)
          pid != nil and Process.alive?(pid)
        rescue
          _ -> false
        end
      end)

    if has_live do
      :erlang.system_time(:millisecond)
    else
      nil
    end
  end

  defp datetime_to_unix(nil), do: nil
  defp datetime_to_unix(%DateTime{} = dt), do: DateTime.to_unix(dt)
  defp datetime_to_unix(_), do: nil
end
