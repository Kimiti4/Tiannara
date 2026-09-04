defmodule Tiannara.CRAV.RuntimeDependencyGraph do
  @moduledoc """
  Phase Ω+ CRAV Runtime Dependency Graph — Deliverable 2.

  Generates the runtime dependency tree automatically by inspecting
  SubsystemRegistry, behaviour declarations, use/import relationships,
  and GenServer call targets.
  """

  require Logger

  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :dependency_graph, :computed]

  @spec graph() :: {:ok, [map()]} | {:error, term()}
  def graph do
    try do
      base_deps = collect_registry_dependencies()
      behaviour_deps = scan_behaviour_declarations()
      use_import_deps = scan_use_import_relationships()
      genserver_deps = scan_genserver_calls()

      all_names = collect_all_subsystem_names(base_deps)

      merged_deps = Enum.reduce(all_names, %{}, fn name, acc ->
        registry = Map.get(base_deps, name, [])
        behaviour = Map.get(behaviour_deps, name, [])
        use_import = Map.get(use_import_deps, name, [])
        genserver = Map.get(genserver_deps, name, [])
        combined = Enum.uniq(registry ++ behaviour ++ use_import ++ genserver)
        Map.put(acc, name, combined)
      end)

      reverse_map = build_reverse_map(merged_deps, all_names)
      cycle_list = detect_cycles(merged_deps, all_names)
      cycle_names = MapSet.new(List.flatten(cycle_list))

      entries = Enum.map(all_names, fn name ->
        deps = Map.get(merged_deps, name, [])
        depended_by = Map.get(reverse_map, name, [])
        has_cycle = MapSet.member?(cycle_names, name)

        %{
          name: name,
          depends_on: deps,
          depended_by: depended_by,
          depth: compute_depth(name, merged_deps),
          is_root: deps == [],
          is_leaf: depended_by == [],
          has_cycle: has_cycle
        }
      end)

      :telemetry.execute(
        @telemetry_event,
        %{total_subsystems: length(entries), cycles_detected: length(cycle_list)},
        %{timestamp: DateTime.utc_now()}
      )

      {:ok, entries}
    rescue
      err -> {:error, {:dependency_graph_failed, err}}
    catch
      kind, reason -> {:error, {:dependency_graph_crashed, kind, reason}}
    end
  end

  @spec roots() :: {:ok, [atom()]} | {:error, term()}
  def roots do
    case graph() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.is_root)) |> Enum.map(&(&1.name))}

      err ->
        err
    end
  end

  @spec leaves() :: {:ok, [atom()]} | {:error, term()}
  def leaves do
    case graph() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.is_leaf)) |> Enum.map(&(&1.name))}

      err ->
        err
    end
  end

  @spec cycles() :: {:ok, [[atom()]]} | {:error, term()}
  def cycles do
    try do
      deps = collect_registry_dependencies()
      names = collect_all_subsystem_names(deps)
      {:ok, detect_cycles(deps, names)}
    rescue
      err -> {:error, {:cycles_detection_failed, err}}
    end
  end

  @spec dependency_report() :: {:ok, String.t()} | {:error, term()}
  def dependency_report do
    case graph() do
      {:ok, entries} ->
        tree = build_tree_string(entries)
        cycle_list = detect_cycles(build_dep_map(entries), collect_names(entries))

        lines = [
          "═══════════════════════════════════════════════════════",
          "  CRAV RUNTIME DEPENDENCY GRAPH",
          "═══════════════════════════════════════════════════════",
          tree,
          "",
          "Cycles Detected: #{length(cycle_list)}"
        ]

        cycle_lines = Enum.flat_map(cycle_list, fn cycle ->
          ["  → #{Enum.join(cycle, " → ")}"]
        end)

        full_lines = lines ++ cycle_lines ++ [
          "",
          "═══════════════════════════════════════════════════════"
        ]

        {:ok, Enum.join(full_lines, "\n")}

      err ->
        err
    end
  end

  defp collect_registry_dependencies do
    try do
      if Code.ensure_loaded?(SubsystemRegistry) and Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
        |> Enum.map(fn r -> {r.name, r.deps || []} end)
        |> Enum.into(%{})
      else
        %{}
      end
    rescue
      _ -> %{}
    catch
      _, _ -> %{}
    end
  end

  defp scan_behaviour_declarations do
    try do
      case :application.get_key(:tiannara, :modules) do
        {:ok, modules} when is_list(modules) ->
          modules
          |> Enum.filter(&Code.ensure_loaded?/1)
          |> Enum.flat_map(fn mod ->
            try do
              attrs = mod.module_info(:attributes)
              behaviours = Keyword.get(attrs, :behaviour, [])

              Enum.map(behaviours, fn behaviour ->
                {mod, behaviour}
              end)
            rescue
              _ -> []
            end
          end)
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
          |> Enum.map(fn {mod, behaviours} ->
            {resolve_subsystem_name(mod), Enum.map(behaviours, &resolve_subsystem_name/1)}
          end)
          |> Enum.reject(fn {name, _} -> name == :unknown end)
          |> Enum.into(%{})

        _ ->
          %{}
      end
    rescue
      _ -> %{}
    end
  end

  defp scan_use_import_relationships do
    try do
      case :application.get_key(:tiannara, :modules) do
        {:ok, modules} when is_list(modules) ->
          modules
          |> Enum.filter(&Code.ensure_loaded?/1)
          |> Enum.flat_map(fn mod ->
            try do
              case :beam_lib.chunks(mod, [:abstract_code]) do
                {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
                  extract_use_import_refs(forms, mod)

                _ ->
                  []
              end
            rescue
              _ -> []
            end
          end)
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
          |> Enum.map(fn {source, targets} ->
            {source, Enum.uniq(targets)}
          end)
          |> Enum.into(%{})

        _ ->
          %{}
      end
    rescue
      _ -> %{}
    end
  end

  defp extract_use_import_refs(forms, source_mod) do
    source_name = resolve_subsystem_name(source_mod)

    if source_name == :unknown do
      []
    else
      bin = :erlang.term_to_binary(forms)
      case :application.get_key(:tiannara, :modules) do
        {:ok, modules} when is_list(modules) ->
          modules
          |> Enum.filter(&Code.ensure_loaded?/1)
          |> Enum.map(&resolve_subsystem_name/1)
          |> Enum.reject(&(&1 == :unknown || &1 == source_name))
          |> Enum.filter(fn target_name ->
            target_str = Atom.to_string(target_name)
            :binary.match(bin, target_str) != :nomatch
          end)
          |> Enum.map(fn target_name -> {source_name, target_name} end)

        _ ->
          []
      end
    end
  end

  defp scan_genserver_calls do
    try do
      case :application.get_key(:tiannara, :modules) do
        {:ok, modules} when is_list(modules) ->
          modules
          |> Enum.filter(&Code.ensure_loaded?/1)
          |> Enum.flat_map(fn mod ->
            try do
              case :beam_lib.chunks(mod, [:abstract_code]) do
                {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
                  extract_genserver_call_targets(forms, mod)

                _ ->
                  []
              end
            rescue
              _ -> []
            end
          end)
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
          |> Enum.map(fn {source, targets} ->
            {source, Enum.uniq(targets)}
          end)
          |> Enum.into(%{})

        _ ->
          %{}
      end
    rescue
      _ -> %{}
    end
  end

  defp extract_genserver_call_targets(forms, source_mod) do
    source_name = resolve_subsystem_name(source_mod)

    if source_name == :unknown do
      []
    else
      bin = :erlang.term_to_binary(forms)
      target_modules = Enum.flat_map(forms, fn form ->
        collect_atom_refs(form)
      end)
      |> Enum.uniq()
      |> Enum.map(&resolve_subsystem_name/1)
      |> Enum.reject(&(&1 == :unknown || &1 == source_name))

      if :binary.match(bin, "GenServer") != :nomatch do
        Enum.map(target_modules, fn target -> {source_name, target} end)
      else
        []
      end
    end
  end

  defp collect_atom_refs({:__aliases__, _, atoms}) when is_list(atoms) do
    last = List.last(atoms)
    if is_atom(last) do
      Enum.filter(atoms, &is_atom/1)
    else
      []
    end
  end

  defp collect_atom_refs(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.flat_map(&collect_atom_refs/1)
  end

  defp collect_atom_refs(list) when is_list(list) do
    Enum.flat_map(list, &collect_atom_refs/1)
  end

  defp collect_atom_refs(_), do: []

  defp resolve_subsystem_name(mod) when is_atom(mod) do
    str = Atom.to_string(mod)

    cond do
      String.starts_with?(str, "Elixir.Tiannara.REA") -> :rea
      String.starts_with?(str, "Elixir.Tiannara.SOPL") -> :sopl
      String.starts_with?(str, "Elixir.Tiannara.CIS") -> :cis
      String.starts_with?(str, "Elixir.Tiannara.MSG") -> :msg
      String.starts_with?(str, "Elixir.Tiannara.OMCE") -> :omce
      String.starts_with?(str, "Elixir.Tiannara.HSV") -> :hsv
      String.starts_with?(str, "Elixir.Tiannara.GRCC") -> :grcc
      String.starts_with?(str, "Elixir.Tiannara.OED") -> :oed
      String.starts_with?(str, "Elixir.Tiannara.CTL") -> :ctl
      String.starts_with?(str, "Elixir.Tiannara.A10") -> :a10
      String.starts_with?(str, "Elixir.Tiannara.ASC") -> :asc
      String.starts_with?(str, "Elixir.Tiannara.WorldModel") -> :world_model
      String.starts_with?(str, "Elixir.Tiannara.Sentinel") -> :sentinel
      String.starts_with?(str, "Elixir.Tiannara.PlanetaryTwin") -> :planetary_twin
      String.starts_with?(str, "Elixir.Tiannara.DiscoveryPipeline") -> :discovery_pipeline
      String.starts_with?(str, "Elixir.Tiannara.EngineeringPipeline") -> :engineering_pipeline
      String.starts_with?(str, "Elixir.Tiannara.SimulationRuntime") -> :simulation_runtime
      String.starts_with?(str, "Elixir.Tiannara.TheoryEcology") -> :theory_ecology
      String.starts_with?(str, "Elixir.Tiannara.KnowledgeGraph") -> :knowledge_graph
      String.starts_with?(str, "Elixir.Tiannara.CivilizationRuntime") -> :civilization_runtime
      String.starts_with?(str, "Elixir.Tiannara.PhaseOmega") -> :phase_omega
      String.starts_with?(str, "Elixir.Tiannara.CRAV") -> :crav
      true -> :unknown
    end
  end

  defp resolve_subsystem_name(_), do: :unknown

  defp collect_all_subsystem_names(registry_deps) do
    registry_names = Map.keys(registry_deps)
    registry_dep_names = registry_deps |> Map.values() |> List.flatten() |> Enum.uniq()

    known = [
      :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
      :a10, :asc, :world_model, :sentinel, :planetary_twin,
      :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
      :theory_ecology, :knowledge_graph, :civilization_runtime
    ]

    (registry_names ++ registry_dep_names ++ known)
    |> Enum.uniq()
    |> Enum.reject(&(&1 == :unknown))
  end

  defp build_reverse_map(dep_map, all_names) do
    Enum.reduce(all_names, %{}, fn name, acc ->
      Map.put(acc, name, [])
    end)
    |> then(fn acc ->
      Enum.reduce(dep_map, acc, fn {source, deps}, inner_acc ->
        Enum.reduce(deps, inner_acc, fn dep, inner2 ->
          Map.update(inner2, dep, [source], fn existing ->
            if source in existing, do: existing, else: [source | existing]
          end)
        end)
      end)
    end)
  end

  defp detect_cycles(dep_map, all_names) do
    Enum.flat_map(all_names, fn start ->
      find_cycles(start, dep_map, [], [])
    end)
    |> Enum.uniq()
  end

  defp find_cycles(current, dep_map, visited, path) do
    if current in path do
      cycle_start = Enum.find_index(path, &(&1 == current))
      {cycle, _} = Enum.split(path, cycle_start)
      [cycle ++ [current]]
    else
      if current in visited do
        []
      else
        deps = Map.get(dep_map, current, [])
        Enum.flat_map(deps, fn dep ->
          find_cycles(dep, dep_map, [current | visited], [current | path])
        end)
      end
    end
  end

  defp compute_depth(name, dep_map, visited \\ MapSet.new()) do
    if MapSet.member?(visited, name) do
      0
    else
      deps = Map.get(dep_map, name, [])

      if deps == [] do
        0
      else
        new_visited = MapSet.put(visited, name)

        deps
        |> Enum.map(fn dep ->
          compute_depth(dep, dep_map, new_visited) + 1
        end)
        |> Enum.max(fn -> 0 end)
      end
    end
  end

  defp build_tree_string(entries) do
    dep_map = entries |> Enum.map(fn e -> {e.name, e.depends_on} end) |> Enum.into(%{})
    reverse_map = build_reverse_map(dep_map, Enum.map(entries, &(&1.name)))

    roots = entries
    |> Enum.filter(&(&1.is_root))
    |> Enum.map(&(&1.name))
    |> Enum.sort()

    case roots do
      [] ->
        all_names = entries |> Enum.map(&(&1.name)) |> Enum.sort()

        case all_names do
          [] -> "(no subsystems registered)"
          _ ->
            all_names
            |> Enum.map(fn name -> render_tree(name, reverse_map, "") end)
            |> List.flatten()
            |> Enum.join("\n")
        end

      _ ->
        roots
        |> Enum.map(fn root -> render_tree(root, reverse_map, "") end)
        |> List.flatten()
        |> Enum.join("\n")
    end
  end

  defp render_tree(name, reverse_map, prefix) do
    children = Map.get(reverse_map, name, [])
    |> Enum.sort()

    label = format_name(name)

    if children == [] do
      [prefix <> label]
    else
      child_lines = Enum.with_index(children, fn child, idx ->
        is_last = idx == length(children) - 1
        connector = if is_last, do: "└── ", else: "├── "
        continuation = if is_last, do: "    ", else: "│   "

        subtree = render_tree(child, reverse_map, prefix <> continuation)

        case subtree do
          [] -> []
          [first | rest] ->
            skip = byte_size(prefix) + byte_size(continuation)
            child_content = binary_part(first, skip, byte_size(first) - skip)
            [prefix <> connector <> child_content | rest]
        end
      end)
      |> List.flatten()

      [prefix <> label] ++ child_lines
    end
  end

  defp format_name(name) when is_atom(name) do
    name |> Atom.to_string() |> String.split(".") |> List.last() |> String.upcase()
  end

  defp format_name(name), do: to_string(name) |> String.upcase()

  defp build_dep_map(entries) do
    entries |> Enum.map(fn e -> {e.name, e.depends_on} end) |> Enum.into(%{})
  end

  defp collect_names(entries) do
    Enum.map(entries, &(&1.name))
  end
end
