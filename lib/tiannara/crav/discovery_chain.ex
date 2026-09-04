defmodule Tiannara.CRAV.DiscoveryChain do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 8 — Discovery Chain.

  Verifies the end-to-end discovery pipeline by checking each stage
  for module presence, reachability, and latency.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :discovery_chain, :verified]

  @stages [
    :observation, :hypothesis, :experiment, :simulation,
    :evidence, :knowledge, :theory, :engineering,
    :certification, :observatory, :replay, :archaeology
  ]

  @stage_modules %{
    observation: Tiannara.REA.Observation,
    hypothesis: Tiannara.REA.Hypothesis,
    experiment: Tiannara.DiscoveryPipeline.Experiment,
    simulation: Tiannara.SimulationRuntime,
    evidence: Tiannara.REA.Evidence,
    knowledge: Tiannara.KnowledgeGraph,
    theory: Tiannara.TheoryEcology,
    engineering: Tiannara.EngineeringPipeline,
    certification: Tiannara.Observatory.Certification,
    observatory: Tiannara.Observatory,
    replay: Tiannara.Observatory.Replay,
    archaeology: Tiannara.Observatory.Archaeology
  }

  @spec verify() :: {:ok, [map()]} | {:error, term()}
  def verify do
    try do
      results = Enum.map(@stages, &verify_stage/1)

      reachable = Enum.count(results, & &1.reachable)
      blocked = Enum.count(results, &(not &1.reachable))
      latencies = Enum.reject(Enum.map(results, & &1.latency_ms), &is_nil/1)
      avg_latency = if latencies != [], do: Enum.sum(latencies) / length(latencies), else: 0

      measurements = %{
        total_stages: length(@stages),
        reachable: reachable,
        blocked: blocked,
        avg_latency_ms: avg_latency
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, results}
    rescue
      err -> {:error, {:discovery_chain_failed, err}}
    catch
      kind, reason -> {:error, {:discovery_chain_crashed, kind, reason}}
    end
  end

  @spec reachable_stages() :: {:ok, [atom()]} | {:error, term()}
  def reachable_stages do
    case verify() do
      {:ok, results} ->
        {:ok, results |> Enum.filter(& &1.reachable) |> Enum.map(& &1.stage)}

      err ->
        err
    end
  end

  @spec blocked_stages() :: {:ok, [atom()]} | {:error, term()}
  def blocked_stages do
    case verify() do
      {:ok, results} ->
        {:ok, results |> Enum.reject(& &1.reachable) |> Enum.map(& &1.stage)}

      err ->
        err
    end
  end

  @spec chain_complete?() :: {:ok, boolean()} | {:error, term()}
  def chain_complete? do
    case verify() do
      {:ok, results} ->
        {:ok, Enum.all?(results, & &1.reachable)}

      err ->
        err
    end
  end

  @spec discovery_chain_report() :: {:ok, String.t()} | {:error, term()}
  def discovery_chain_report do
    case verify() do
      {:ok, results} ->
        now = DateTime.utc_now()
        reachable = Enum.count(results, & &1.reachable)
        blocked = Enum.count(results, &(not &1.reachable))
        complete = blocked == 0

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV DISCOVERY CHAIN — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Stages: #{length(@stages)}  |  Reachable: #{reachable}  |  Blocked: #{blocked}  |  Complete: #{complete}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(results, fn r ->
              status = if r.reachable, do: "✓", else: "✗"
              name = r.stage |> Atom.to_string() |> String.pad_trailing(18)
              latency = format_latency(r.latency_ms)
              err = if r.error, do: " ERR: #{r.error}", else: ""

              "  #{status} #{name} latency=#{latency}#{err}"
            end) ++
            build_flow_line(results) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp verify_stage(stage) do
    mod = Map.get(@stage_modules, stage)

    cond do
      is_nil(mod) ->
        %{
          stage: stage,
          module: nil,
          reachable: false,
          latency_ms: nil,
          timestamp: nil,
          error: "no module mapped"
        }

      not Code.ensure_loaded?(mod) ->
        %{
          stage: stage,
          module: mod,
          reachable: false,
          latency_ms: nil,
          timestamp: nil,
          error: "module not loaded"
        }

      true ->
        probe_module(stage, mod)
    end
  end

  defp probe_module(stage, mod) do
    start_us = System.monotonic_time(:microsecond)

    result =
      try do
        cond do
          function_exported?(mod, :status, 0) ->
            apply(mod, :status, [])

          function_exported?(mod, :ping, 0) ->
            apply(mod, :ping, [])

          function_exported?(mod, :info, 0) ->
            apply(mod, :info, [])

          Process.whereis(mod) != nil ->
            :alive

          true ->
            :no_probe
        end
      rescue
        err -> {:error, Exception.message(err)}
      catch
        kind, reason -> {:error, "#{kind}: #{reason}"}
      end

    elapsed_us = System.monotonic_time(:microsecond) - start_us
    elapsed_ms = div(elapsed_us, 1000)
    ts = System.system_time(:millisecond)

    case result do
      {:error, msg} ->
        %{
          stage: stage,
          module: mod,
          reachable: false,
          latency_ms: elapsed_ms,
          timestamp: ts,
          error: msg
        }

      :no_probe ->
        %{
          stage: stage,
          module: mod,
          reachable: true,
          latency_ms: elapsed_ms,
          timestamp: ts,
          error: nil
        }

      _ ->
        %{
          stage: stage,
          module: mod,
          reachable: true,
          latency_ms: elapsed_ms,
          timestamp: ts,
          error: nil
        }
    end
  end

  defp format_latency(nil), do: "n/a"
  defp format_latency(ms), do: "#{ms}ms"

  defp build_flow_line(results) do
    symbols =
      Enum.map(results, fn r ->
        if r.reachable, do: "●", else: "○"
      end)

    arrow_line =
      symbols
      |> Enum.join(" → ")

    ["  Chain: #{arrow_line}"]
  end
end
