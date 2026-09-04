defmodule Tiannara.CRAV.DeadCodeDetector do
  @moduledoc """
  Phase Ω+ CRAV Dead Code Detector — Deliverable 5.

  Identifies dormant systems — compiled but never started, never called,
  never publishing. Scans all Tiannara modules and classifies each as
  alive, dormant, deprecated, test_only, infrastructure, or planned.
  """

  require Logger

  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :dead_code, :detected]

  @infrastructure_suffixes [
    "Application", "MixProject", "Endpoint", "Router",
    "Repo", "Mailer", "Release"
  ]

  @spec detect() :: {:ok, [map()]} | {:error, term()}
  def detect do
    try do
      modules = discover_modules()
      supervised_modules = collect_supervised_modules()
      call_graph = build_call_graph(modules)

      classifications =
        modules
        |> Enum.map(&classify_module(&1, supervised_modules, call_graph))

      total = length(classifications)
      dormant = Enum.count(classifications, &(&1.classification == :dormant))

      :telemetry.execute(
        @telemetry_event,
        %{total: total, dormant: dormant},
        %{timestamp: DateTime.utc_now()}
      )

      {:ok, classifications}
    rescue
      err -> {:error, {:detection_failed, err}}
    catch
      kind, reason -> {:error, {:detection_crashed, kind, reason}}
    end
  end

  @spec dormant_modules() :: {:ok, [module()]} | {:error, term()}
  def dormant_modules do
    case detect() do
      {:ok, classifications} ->
        {:ok,
         classifications
         |> Enum.filter(&(&1.classification == :dormant))
         |> Enum.map(& &1.module)}

      err ->
        err
    end
  end

  @spec alive_modules() :: {:ok, [module()]} | {:error, term()}
  def alive_modules do
    case detect() do
      {:ok, classifications} ->
        {:ok,
         classifications
         |> Enum.filter(&(&1.classification == :alive))
         |> Enum.map(& &1.module)}

      err ->
        err
    end
  end

  @spec planned_modules() :: {:ok, [module()]} | {:error, term()}
  def planned_modules do
    case detect() do
      {:ok, classifications} ->
        {:ok,
         classifications
         |> Enum.filter(&(&1.classification == :planned))
         |> Enum.map(& &1.module)}

      err ->
        err
    end
  end

  @spec dormancy_report() :: {:ok, String.t()} | {:error, term()}
  def dormancy_report do
    case detect() do
      {:ok, classifications} ->
        now = DateTime.utc_now()
        total = length(classifications)
        alive = Enum.count(classifications, &(&1.classification == :alive))
        dormant = Enum.count(classifications, &(&1.classification == :dormant))
        planned = Enum.count(classifications, &(&1.classification == :planned))
        deprecated = Enum.count(classifications, &(&1.classification == :deprecated))
        infra = Enum.count(classifications, &(&1.classification == :infrastructure))
        test_only = Enum.count(classifications, &(&1.classification == :test_only))
        pct = if total > 0, do: Float.round(dormant / total * 100, 1), else: 0.0

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV DEAD CODE REPORT — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Total: #{total}  |  Alive: #{alive}  |  Dormant: #{dormant}  |  Planned: #{planned}",
            "  Deprecated: #{deprecated}  |  Infrastructure: #{infra}  |  Test-only: #{test_only}",
            "  Dormancy: #{pct}%",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(classifications, fn c ->
              icon =
                case c.classification do
                  :alive -> "OK"
                  :dormant -> "XX"
                  :planned -> "PL"
                  :deprecated -> "DE"
                  :infrastructure -> "IN"
                  :test_only -> "TT"
                end

              "  [#{icon}] #{pad_module(c.module, 55)} #{c.reason}"
            end) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  @spec dormancy_percentage() :: {:ok, float()} | {:error, term()}
  def dormancy_percentage do
    case detect() do
      {:ok, classifications} ->
        total = length(classifications)
        dormant = Enum.count(classifications, &(&1.classification == :dormant))
        {:ok, if(total > 0, do: dormant / total, else: 0.0)}

      err ->
        err
    end
  end

  defp discover_modules do
    case :application.get_key(:tiannara, :modules) do
      {:ok, modules} when is_list(modules) ->
        modules
        |> Enum.filter(&tiannara_module?/1)
        |> Enum.sort()

      _ ->
        []
    end
  end

  defp tiannara_module?(mod) when is_atom(mod) do
    str = Atom.to_string(mod)
    String.starts_with?(str, "Elixir.Tiannara") || String.starts_with?(str, "Elixir.TiannaraOS")
  end

  defp tiannara_module?(_), do: false

  defp classify_module(mod, supervised_modules, call_graph) do
    short_name = Atom.to_string(mod) |> String.replace("Elixir.", "")

    cond do
      stub_module?(short_name) ->
        build_result(mod, :planned, "Stub module — planned, not yet implemented", supervised_modules, call_graph)

      deprecated_module?(mod, short_name) ->
        build_result(mod, :deprecated, "Module marked as deprecated", supervised_modules, call_graph)

      test_only_module?(short_name) ->
        build_result(mod, :test_only, "Only used in test environment", supervised_modules, call_graph)

      infrastructure_module?(short_name) ->
        build_result(mod, :infrastructure, "Infrastructure support module", supervised_modules, call_graph)

      alive_module?(mod, supervised_modules, call_graph) ->
        build_result(mod, :alive, "Running, active, participating", supervised_modules, call_graph)

      true ->
        reasons = dormancy_reasons(mod, supervised_modules, call_graph)

        reason =
          if reasons == [],
            do: "Compiled but never started or called",
            else: Enum.join(reasons, "; ")

        build_result(mod, :dormant, reason, supervised_modules, call_graph)
    end
  end

  defp stub_module?(name) do
    parts = String.split(name, ".")
    last = List.last(parts) || ""
    String.contains?(name, "Stub") || String.starts_with?(String.downcase(last), "stub")
  end

  defp deprecated_module?(mod, short_name) do
    try do
      attrs =
        try do
          mod.module_info(:attributes)
        rescue
          _ -> []
        end

      Keyword.has_key?(attrs, :deprecated) ||
        String.contains?(short_name, "Deprecated") ||
        String.contains?(short_name, "deprecated")
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp test_only_module?(name) do
    String.contains?(name, ".Test.") ||
      String.contains?(name, "TestSupport") ||
      String.ends_with?(name, "TestHelper") ||
      String.ends_with?(name, "TestFactory") ||
      String.contains?(name, "Test.Mock")
  end

  defp infrastructure_module?(name) do
    parts = String.split(name, ".")
    last = List.last(parts) || ""

    Enum.any?(@infrastructure_suffixes, &String.ends_with?(last, &1)) ||
      String.ends_with?(name, ".Telemetry") ||
      String.ends_with?(name, ".Endpoint") ||
      String.ends_with?(name, ".Router")
  end

  defp alive_module?(mod, supervised_modules, call_graph) do
    has_process?(mod) ||
      MapSet.member?(supervised_modules, mod) ||
      telemetry_emit?(mod) ||
      telemetry_subscribe?(mod) ||
      has_callers?(mod, call_graph)
  end

  defp has_process?(mod) do
    cond do
      function_exported?(mod, :start_link, 1) ->
        pid = Process.whereis(mod)
        pid != nil && Process.alive?(pid)

      function_exported?(mod, :start, 1) ->
        pid = Process.whereis(mod)
        pid != nil && Process.alive?(pid)

      true ->
        false
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  defp telemetry_emit?(mod) do
    abstract_contains?(mod, "execute") && abstract_contains?(mod, "telemetry")
  end

  defp telemetry_subscribe?(mod) do
    (abstract_contains?(mod, "attach") && abstract_contains?(mod, "telemetry")) ||
      (abstract_contains?(mod, "attach_many") && abstract_contains?(mod, "telemetry"))
  end

  defp has_callers?(mod, call_graph) do
    callers = Map.get(call_graph, mod, [])
    callers != []
  end

  defp abstract_contains?(mod, pattern) do
    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          bin = :erlang.term_to_binary(forms)
          :binary.match(bin, pattern) != :nomatch

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp build_call_graph(modules) do
    target_strings = Enum.map(modules, &Atom.to_string/1) |> MapSet.new()

    refs_per_module =
      Enum.map(modules, fn mod ->
        {mod, find_references(mod, target_strings)}
      end)

    Enum.reduce(refs_per_module, %{}, fn {source, targets}, acc ->
      Enum.reduce(targets, acc, fn target, inner ->
        Map.update(inner, target, [source], &[source | &1])
      end)
    end)
  end

  defp find_references(mod, target_strings) do
    my_str = Atom.to_string(mod)

    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          bin = :erlang.term_to_binary(forms)

          target_strings
          |> Enum.filter(fn s ->
            s != my_str && :binary.match(bin, s) != :nomatch
          end)
          |> Enum.map(&String.to_atom/1)

        _ ->
          []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp dormancy_reasons(mod, supervised_modules, call_graph) do
    reasons = []

    reasons =
      if not has_start_fn?(mod),
        do: ["no start_link/1 or start/1" | reasons],
        else: reasons

    reasons =
      if not MapSet.member?(supervised_modules, mod),
        do: ["not supervised" | reasons],
        else: reasons

    reasons =
      if not telemetry_emit?(mod),
        do: ["no telemetry events" | reasons],
        else: reasons

    reasons =
      if not telemetry_subscribe?(mod),
        do: ["no telemetry subscriptions" | reasons],
        else: reasons

    reasons =
      if not has_callers?(mod, call_graph),
        do: ["never called by other modules" | reasons],
        else: reasons

    Enum.reverse(reasons)
  end

  defp has_start_fn?(mod) do
    function_exported?(mod, :start_link, 1) || function_exported?(mod, :start, 1)
  rescue
    _ -> false
  end

  defp collect_supervised_modules do
    try do
      if Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
        |> Enum.map(& &1.module)
        |> Enum.filter(&is_atom/1)
        |> MapSet.new()
      else
        MapSet.new()
      end
    rescue
      _ -> MapSet.new()
    catch
      _, _ -> MapSet.new()
    end
  end

  defp build_result(mod, classification, reason, supervised_modules, call_graph) do
    %{
      module: mod,
      classification: classification,
      reason: reason,
      has_process: has_process?(mod),
      has_telemetry_emit: telemetry_emit?(mod),
      has_telemetry_subscribe: telemetry_subscribe?(mod),
      supervised: MapSet.member?(supervised_modules, mod),
      called_by: Map.get(call_graph, mod, []),
      line_count: estimate_line_count(mod)
    }
  end

  defp estimate_line_count(mod) do
    try do
      source = mod.module_info(:compile)[:source]

      if source do
        case File.read(to_string(source)) do
          {:ok, content} -> content |> String.split("\n") |> length()
          _ -> from_abstract_lines(mod)
        end
      else
        from_abstract_lines(mod)
      end
    rescue
      _ -> from_abstract_lines(mod)
    catch
      _, _ -> from_abstract_lines(mod)
    end
  end

  defp from_abstract_lines(mod) do
    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          forms
          |> Enum.flat_map(fn form ->
            try do
              extract_line(form)
            rescue
              _ -> []
            end
          end)
          |> Enum.filter(&is_integer/1)
          |> case do
            [] -> 0
            lines -> Enum.max(lines)
          end

        _ ->
          0
      end
    rescue
      _ -> 0
    catch
      _, _ -> 0
    end
  end

  defp extract_line(tuple) when is_tuple(tuple) and tuple_size(tuple) >= 3 do
    try do
      line = elem(tuple, 1)
      if is_integer(line) and line > 0, do: [line], else: []
    rescue
      _ -> []
    end
  end

  defp extract_line(_), do: []

  defp pad_module(mod, width) when is_atom(mod) do
    str = Atom.to_string(mod) |> String.replace("Elixir.", "")
    String.pad_trailing(str, width)
  end

  defp pad_module(other, width) do
    str = to_string(other)
    String.pad_trailing(str, width)
  end
end
