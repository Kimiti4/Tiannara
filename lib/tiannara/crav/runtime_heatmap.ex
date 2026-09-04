defmodule Tiannara.CRAV.RuntimeHeatmap do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 14 — Runtime Heatmap.

  Visualizes system activity as hot/warm/cold/dormant by
  introspecting process message rates, telemetry event frequency,
  SubsystemRegistry heartbeat timestamps, and memory usage.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :heatmap, :computed]

  @subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime
  ]

  @subsystem_modules %{
    rea: [Tiannara.REA, Tiannara.REA.Supervisor],
    sopl: [Tiannara.SOPL, Tiannara.SOPL.Supervisor],
    cis: [Tiannara.CIS, Tiannara.CIS.Supervisor],
    msg: [Tiannara.MSG, Tiannara.MSG.Supervisor],
    omce: [Tiannara.OMCE, Tiannara.OMCE.Supervisor],
    hsv: [Tiannara.HSV, Tiannara.HSV.Supervisor],
    grcc: [Tiannara.GRCC, Tiannara.GRCC.Supervisor],
    oed: [Tiannara.OED, Tiannara.OED.Supervisor],
    ctl: [Tiannara.CTL, Tiannara.CTL.Supervisor],
    a10: [Tiannara.A10, Tiannara.A10.Supervisor],
    asc: [Tiannara.ASC, Tiannara.ASC.Supervisor],
    world_model: [Tiannara.WorldModel, Tiannara.WorldModel.Supervisor],
    sentinel: [Tiannara.Sentinel, Tiannara.Sentinel.Supervisor],
    planetary_twin: [Tiannara.PlanetaryTwin, Tiannara.PlanetaryTwin.Supervisor],
    discovery_pipeline: [Tiannara.DiscoveryPipeline, Tiannara.DiscoveryPipeline.Supervisor],
    engineering_pipeline: [Tiannara.EngineeringPipeline, Tiannara.EngineeringPipeline.Supervisor],
    simulation_runtime: [Tiannara.SimulationRuntime, Tiannara.SimulationRuntime.Supervisor],
    theory_ecology: [Tiannara.TheoryEcology, Tiannara.TheoryEcology.Supervisor],
    knowledge_graph: [Tiannara.KnowledgeGraph, Tiannara.KnowledgeGraph.Supervisor],
    civilization_runtime: [Tiannara.CivilizationRuntime, Tiannara.CivilizationRuntime.Supervisor]
  }

  @display_names %{
    rea: "REA",
    sopl: "SOPL",
    cis: "CIS",
    msg: "MSG",
    omce: "OMCE",
    hsv: "HSV",
    grcc: "GRCC",
    oed: "OED",
    ctl: "CTL",
    a10: "A10",
    asc: "ASC",
    world_model: "World Model",
    sentinel: "Sentinel",
    planetary_twin: "Planetary Twin",
    discovery_pipeline: "Discovery Pipeline",
    engineering_pipeline: "Engineering Pipeline",
    simulation_runtime: "Simulation Runtime",
    theory_ecology: "Theory Ecology",
    knowledge_graph: "Knowledge Graph",
    civilization_runtime: "Civilization Runtime"
  }

  @spec heatmap() :: {:ok, [map()]} | {:error, term()}
  def heatmap do
    try do
      entries = Enum.map(@subsystems, &probe_subsystem/1)

      hot = Enum.count(entries, &(&1.temperature == :hot))
      warm = Enum.count(entries, &(&1.temperature == :warm))
      cold = Enum.count(entries, &(&1.temperature == :cold))
      dormant = Enum.count(entries, &(&1.temperature == :dormant))

      measurements = %{
        total: length(entries),
        hot: hot,
        warm: warm,
        cold: cold,
        dormant: dormant
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:heatmap_computation_failed, err}}
    catch
      kind, reason -> {:error, {:heatmap_crashed, kind, reason}}
    end
  end

  @spec hot_subsystems() :: {:ok, [atom()]} | {:error, term()}
  def hot_subsystems do
    case heatmap() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.temperature == :hot)) |> Enum.map(& &1.name)}

      err ->
        err
    end
  end

  @spec dormant_subsystems() :: {:ok, [atom()]} | {:error, term()}
  def dormant_subsystems do
    case heatmap() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.temperature == :dormant)) |> Enum.map(& &1.name)}

      err ->
        err
    end
  end

  @spec heatmap_report() :: {:ok, String.t()} | {:error, term()}
  def heatmap_report do
    case heatmap() do
      {:ok, entries} ->
        header = String.pad_trailing("Subsystem", 24) <> "Temperature"
        separator = String.duplicate("-", 36)

        rows =
          entries
          |> Enum.sort_by(& &1.activity_score, :desc)
          |> Enum.map(fn entry ->
            name = Map.get(@display_names, entry.name, Atom.to_string(entry.name))
            name_str = String.pad_trailing(name, 24)
            indicator = temperature_indicator(entry.temperature)
            temp_str = temperature_label(entry.temperature)
            name_str <> "#{indicator} #{temp_str}"
          end)

        report = [header, separator | rows] |> Enum.join("\n")
        {:ok, report}

      err ->
        err
    end
  end

  defp probe_subsystem(name) do
    mods = Map.get(@subsystem_modules, name, [])
    pids = find_pids(mods)

    messages_per_second = compute_messages_per_second(pids)
    cpu_usage = compute_cpu_usage(pids)
    memory_bytes = compute_memory(pids)
    last_activity = fetch_last_activity(name)

    activity_score =
      compute_activity_score(name, pids, messages_per_second, cpu_usage, last_activity)

    temperature = classify_temperature(activity_score)

    %{
      name: name,
      temperature: temperature,
      activity_score: Float.round(activity_score, 4),
      messages_per_second: Float.round(messages_per_second, 2),
      cpu_usage: cpu_usage,
      memory_bytes: memory_bytes,
      last_activity: last_activity
    }
  end

  defp find_pids(mods) do
    mods
    |> Enum.map(fn mod ->
      case Process.whereis(mod) do
        pid when is_pid(pid) and is_pid(pid) ->
          if Process.alive?(pid), do: pid, else: nil

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp compute_messages_per_second([]), do: 0.0

  defp compute_messages_per_second(pids) do
    total_queue =
      pids
      |> Enum.map(fn pid ->
        case safe_process_info(pid, :message_queue_len) do
          {:message_queue_len, len} when is_integer(len) -> len
          _ -> 0
        end
      end)
      |> Enum.sum()

    telemetry_rate = telemetry_event_rate(pids)

    Float.round(total_queue * 0.1 + telemetry_rate, 4)
  end

  defp compute_cpu_usage([]), do: nil

  defp compute_cpu_usage(pids) do
    reductions =
      pids
      |> Enum.map(fn pid ->
        case safe_process_info(pid, :reductions) do
          {:reductions, r} when is_integer(r) -> r
          _ -> 0
        end
      end)
      |> Enum.sum()

    Float.round(min(reductions / 1_000_000, 1.0), 4)
  end

  defp compute_memory([]), do: 0

  defp compute_memory(pids) do
    pids
    |> Enum.map(fn pid ->
      case safe_process_info(pid, :memory) do
        {:memory, mem} when is_integer(mem) -> mem
        _ -> 0
      end
    end)
    |> Enum.sum()
  end

  defp fetch_last_activity(name) do
    try do
      if Code.ensure_loaded?(Tiannara.PhaseOmega.SubsystemRegistry) do
        case Tiannara.PhaseOmega.SubsystemRegistry.get(name) do
          nil ->
            nil

          record ->
            case record.last_activity do
              nil -> nil
              %DateTime{} = dt -> DateTime.to_unix(dt)
              other -> other
            end
        end
      else
        nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp compute_activity_score(name, pids, messages_per_second, _cpu_usage, last_activity) do
    pid_score = if length(pids) > 0, do: min(length(pids) * 0.2, 0.4), else: 0.0
    msg_score = min(messages_per_second / 100, 0.3)

    heartbeat_score =
      case last_activity do
        nil ->
          0.0

        unix when is_integer(unix) ->
          elapsed_sec = System.system_time(:second) - unix
          cond do
            elapsed_sec < 60 -> 0.3
            elapsed_sec < 300 -> 0.2
            elapsed_sec < 3600 -> 0.1
            true -> 0.0
          end

        _ ->
          0.0
    end

    telemetry_score = telemetry_handler_score(name)

    min(1.0, pid_score + msg_score + heartbeat_score + telemetry_score)
  end

  defp telemetry_event_rate(pids) do
    Enum.reduce(pids, 0.0, fn pid, acc ->
      case safe_process_info(pid, :reductions) do
        {:reductions, r} when is_integer(r) -> acc + min(r / 10_000, 50.0)
        _ -> acc
      end
    end)
  end

  defp telemetry_handler_score(name) do
    try do
      handlers = :telemetry.list_handlers([:tiannara, name])
      min(length(handlers) * 0.05, 0.1)
    rescue
      _ -> 0.0
    catch
      _, _ -> 0.0
    end
  end

  defp classify_temperature(score) do
    cond do
      score > 0.8 -> :hot
      score > 0.3 -> :warm
      score > 0.0 -> :cold
      true -> :dormant
    end
  end

  defp temperature_indicator(:hot), do: "\u{1F525}"
  defp temperature_indicator(:warm), do: "\u{1F7E1}"
  defp temperature_indicator(:cold), do: "\u{1F9CA}"
  defp temperature_indicator(:dormant), do: "\u{1F9CA}\u{FE0F} "

  defp temperature_label(:hot), do: "HOT"
  defp temperature_label(:warm), do: "WARM"
  defp temperature_label(:cold), do: "COLD"
  defp temperature_label(:dormant), do: "DORMANT"

  defp safe_process_info(pid, key) do
    try do
      if Process.alive?(pid) do
        Process.info(pid, key)
      else
        nil
      end
    rescue
      _ -> nil
    end
  end
end
