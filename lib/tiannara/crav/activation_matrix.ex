defmodule Tiannara.CRAV.ActivationMatrix do
  @moduledoc """
  Ω+ CRAV Deliverable 3 — Activation Matrix.

  Generates a binary matrix showing which subsystems are active vs dormant
  by introspecting the BEAM runtime, supervision trees, telemetry handlers,
  and Observatory configuration.
  """

  @participation_threshold_minutes 5
  @participation_threshold_ms @participation_threshold_minutes * 60 * 1000

  @subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime
  ]

  @observable_subsystems MapSet.new([
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime
  ])

  @subsystem_modules %{
    rea: {Tiannara.REA, Tiannara.REA.Supervisor},
    sopl: {Tiannara.SOPL, Tiannara.SOPL.Supervisor},
    cis: {Tiannara.CIS, Tiannara.CIS.Supervisor},
    msg: {Tiannara.MSG, Tiannara.MSG.Supervisor},
    omce: {Tiannara.OMCE, Tiannara.OMCE.Supervisor},
    hsv: {Tiannara.HSV, Tiannara.HSV.Supervisor},
    grcc: {Tiannara.GRCC, Tiannara.GRCC.Supervisor},
    oed: {Tiannara.OED, Tiannara.OED.Supervisor},
    ctl: {Tiannara.CTL, Tiannara.CTL.Supervisor},
    a10: {Tiannara.A10, Tiannara.A10.Supervisor},
    asc: {Tiannara.ASC, Tiannara.ASC.Supervisor},
    world_model: {Tiannara.WorldModel, Tiannara.WorldModel.Supervisor},
    sentinel: {Tiannara.Sentinel, Tiannara.Sentinel.Supervisor},
    planetary_twin: {Tiannara.PlanetaryTwin, Tiannara.PlanetaryTwin.Supervisor},
    discovery_pipeline: {Tiannara.DiscoveryPipeline, Tiannara.DiscoveryPipeline.Supervisor},
    engineering_pipeline: {Tiannara.EngineeringPipeline, Tiannara.EngineeringPipeline.Supervisor},
    simulation_runtime: {Tiannara.SimulationRuntime, Tiannara.SimulationRuntime.Supervisor},
    theory_ecology: {Tiannara.TheoryEcology, Tiannara.TheoryEcology.Supervisor},
    knowledge_graph: {Tiannara.KnowledgeGraph, Tiannara.KnowledgeGraph.Supervisor},
    civilization_runtime: {Tiannara.CivilizationRuntime, Tiannara.CivilizationRuntime.Supervisor}
  }

  @type overall_status :: :active | :dormant | :degraded | :failed

  @type entry :: %{
    name: atom(),
    compiled: boolean(),
    loaded: boolean(),
    supervisor_started: boolean(),
    worker_started: boolean(),
    receiving_events: boolean(),
    publishing_events: boolean(),
    participating: boolean(),
    observable: boolean(),
    overall: overall_status()
  }

  @spec matrix() :: {:ok, [entry()]} | {:error, term()}
  def matrix do
    entries = Enum.map(@subsystems, &probe_subsystem/1)

    :telemetry.execute(
      [:tiannara, :crav, :activation, :computed],
      %{
        total: length(entries),
        active: count_by_overall(entries, :active),
        dormant: count_by_overall(entries, :dormant),
        degraded: count_by_overall(entries, :degraded),
        failed: count_by_overall(entries, :failed)
      },
      %{timestamp: DateTime.utc_now()}
    )

    {:ok, entries}
  rescue
    error -> {:error, {:matrix_computation_failed, error}}
  end

  @spec active_subsystems() :: {:ok, [atom()]} | {:error, term()}
  def active_subsystems do
    case matrix() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.overall == :active)) |> Enum.map(& &1.name)}

      error ->
        error
    end
  end

  @spec dormant_subsystems() :: {:ok, [atom()]} | {:error, term()}
  def dormant_subsystems do
    case matrix() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.overall == :dormant)) |> Enum.map(& &1.name)}

      error ->
        error
    end
  end

  @spec activation_score() :: {:ok, float()} | {:error, term()}
  def activation_score do
    case matrix() do
      {:ok, entries} ->
        total = length(entries)

        if total == 0 do
          {:ok, 0.0}
        else
          active = count_by_overall(entries, :active)
          {:ok, active / total}
        end

      error ->
        error
    end
  end

  @spec formatted_report() :: {:ok, String.t()} | {:error, term()}
  def formatted_report do
    case matrix() do
      {:ok, entries} ->
        header = String.pad_trailing("Subsystem", 24) <> "Active"
        separator = String.duplicate("-", 30)

        rows =
          entries
          |> Enum.map(fn entry ->
            label = entry.name |> Atom.to_string() |> String.upcase() |> String.pad_trailing(24)
            status = if entry.overall == :active, do: "YES", else: "NO"
            label <> status
          end)

        report = [header, separator | rows] |> Enum.join("\n")
        {:ok, report}

      error ->
        error
    end
  end

  defp probe_subsystem(name) do
    {primary_module, supervisor_module} =
      Map.get(@subsystem_modules, name, {nil, nil})

    compiled = check_compiled(primary_module)
    loaded = check_loaded(primary_module)
    supervisor_started = check_supervisor_started(supervisor_module)
    worker_started = check_worker_started(supervisor_module)
    receiving_events = check_receiving_events(primary_module)
    publishing_events = check_publishing_events(primary_module)
    participating = check_participating(name)
    observable = check_observable(name)

    overall =
      determine_overall(
        compiled,
        loaded,
        supervisor_started,
        worker_started,
        participating
      )

    %{
      name: name,
      compiled: compiled,
      loaded: loaded,
      supervisor_started: supervisor_started,
      worker_started: worker_started,
      receiving_events: receiving_events,
      publishing_events: publishing_events,
      participating: participating,
      observable: observable,
      overall: overall
    }
  end

  defp check_compiled(nil), do: false

  defp check_compiled(module) do
    Code.ensure_loaded?(module)
  end

  defp check_loaded(nil), do: false

  defp check_loaded(module) do
    case :code.is_loaded(module) do
      {:module, _} -> true
      _ -> false
    end
  end

  defp check_supervisor_started(nil), do: false

  defp check_supervisor_started(supervisor_module) do
    case Process.whereis(supervisor_module) do
      pid when is_pid(pid) -> Process.alive?(pid)
      _ -> false
    end
  end

  defp check_worker_started(nil), do: false

  defp check_worker_started(supervisor_module) do
    case Process.whereis(supervisor_module) do
      pid when is_pid(pid) ->
        try do
          children = Supervisor.which_children(pid)

          Enum.any?(children, fn
            {_id, child_pid, _type, _mods} when is_pid(child_pid) -> Process.alive?(child_pid)
            _ -> false
          end)
        rescue
          _ -> false
        catch
          _, _ -> false
        end

      _ ->
        false
    end
  end

  defp check_receiving_events(nil), do: false

  defp check_receiving_events(module) do
    registry_check =
      try do
        case Tiannara.PhaseOmega.SubsystemRegistry.all() do
          records when is_list(records) ->
            Enum.any?(records, fn r ->
              r.module == module && r.observability in [:telemetry_enabled, :partially_observed]
            end)

          _ ->
            false
        end
      rescue
        _ -> false
      catch
        _, _ -> false
      end

    handler_check =
      try do
        event_patterns = [
          [:tiannara, :subsystem],
          [:tiannara, :phase_omega],
          [:tiannara, :crav]
        ]

        Enum.any?(event_patterns, fn pattern ->
          :telemetry.list_handlers(pattern)
          |> Enum.any?(fn handler ->
            case handler do
              %{id: {mod, _}} -> mod == module
              %{id: mod} -> mod == module
              _ -> false
            end
          end)
        end)
      rescue
        _ -> false
      catch
        _, _ -> false
      end

    registry_check || handler_check
  end

  defp check_publishing_events(nil), do: false

  defp check_publishing_events(module) do
    try do
      case module.__info__(:functions) do
        fns when is_list(fns) ->
          Enum.any?(fns, fn {name, _arity} ->
            Atom.to_string(name) |> String.contains?("emit") ||
              Atom.to_string(name) |> String.contains?("publish") ||
              Atom.to_string(name) |> String.contains?("telemetry")
          end)

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp check_participating(name) do
    try do
      case Tiannara.PhaseOmega.SubsystemRegistry.get(name) do
        nil ->
          false

        record ->
          case record.last_activity do
            nil ->
              false

            last_activity ->
              elapsed_ms =
                DateTime.diff(DateTime.utc_now(), last_activity, :millisecond)

              elapsed_ms < @participation_threshold_ms
          end
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp check_observable(name) do
    MapSet.member?(@observable_subsystems, name)
  end

  defp determine_overall(compiled, loaded, supervisor_started, worker_started, participating) do
    cond do
      !compiled || !loaded ->
        :dormant

      !supervisor_started ->
        :failed

      !worker_started ->
        :degraded

      !participating ->
        :degraded

      true ->
        :active
    end
  end

  defp count_by_overall(entries, status) do
    Enum.count(entries, &(&1.overall == status))
  end
end
