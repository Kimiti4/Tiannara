defmodule Mix.Tasks.Asc.Observe do
  @moduledoc """
  Post-adoption observation snapshot. Read-only measurement: restarts
  RepairLibrary standalone N times (supervision tree NOT started — mix task
  runs app.config only), records ingestion p50, ETS size, archive line count,
  VM memory. Writes priv/asc/adoptions/observations/<mission>/<label>.eterm
  and compares against day0 when present.
  """
  use Mix.Task

  @shortdoc "Capture a post-adoption observation snapshot"

  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [n: :integer, label: :string, mission: :string, archive: :string])

    Mix.Task.run("app.config")

    mission = opts[:mission] || "ASC-AE-003"
    label = opts[:label] || (DateTime.utc_now() |> DateTime.to_iso8601())
    n = opts[:n] || 7
    target = Tiannara.ASC.Crucible.RepairLibrary

    unless Code.ensure_loaded?(target) and function_exported?(target, :start_link, 1) do
      Mix.shell().error("OBSERVE_ABORT: target module shape mismatch")
      exit({:shutdown, 1})
    end

    samples =
      for _ <- 1..n do
        case Process.whereis(target) do
          nil -> :ok
          pid -> GenServer.stop(pid, :normal, 15_000)
        end

        {us, result} = :timer.tc(fn -> target.start_link([]) end)

        case result do
          {:ok, _pid} ->
            %{ms: us / 1_000, ets_size: :ets.info(:repair_library, :size)}

          other ->
            Mix.shell().error("OBSERVE_ABORT: start_link failed: #{inspect(other)}")
            exit({:shutdown, 1})
        end
      end

    case Process.whereis(target) do
      nil -> :ok
      pid -> GenServer.stop(pid, :normal, 15_000)
    end

    lats = samples |> Enum.map(& &1.ms) |> Enum.sort()

    archive_path =
      opts[:archive] ||
        (Application.get_env(:tiannara, :asc, []) |> Keyword.get(:repair_library_persistence_file)) ||
        "data/repair_patterns.ndjson"

    archive_lines =
      if File.exists?(archive_path), do: archive_path |> File.stream!() |> Enum.count(), else: :missing

    snap = %{
      mission: mission,
      label: label,
      at: DateTime.utc_now() |> DateTime.to_iso8601(),
      ingestion_p50_ms: Enum.at(lats, div(n, 2)),
      samples_ms: Enum.map(samples, & &1.ms),
      ets_size: List.last(samples).ets_size,
      archive_lines: archive_lines,
      memory_total_mb: :erlang.memory(:total) / 1_048_576
    }

    dir = Path.join(["priv/asc/adoptions/observations", mission])
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{label}.eterm")
    File.write!(path, :erlang.term_to_binary(snap))

    IO.puts("snapshot: #{path}")
    IO.puts("ingestion p50: #{Float.round(snap.ingestion_p50_ms, 3)} ms | ets_size: #{inspect(snap.ets_size)} | archive_lines: #{inspect(archive_lines)} | mem: #{Float.round(snap.memory_total_mb, 1)} MB")

    day0 = Path.join(dir, "day0.eterm")

    if label != "day0" and File.exists?(day0) do
      base = :erlang.binary_to_term(File.read!(day0))
      delta = (snap.ingestion_p50_ms - base.ingestion_p50_ms) / base.ingestion_p50_ms
      IO.puts("vs day0: p50 delta #{Float.round(delta * 100, 1)}% | ets #{inspect(base.ets_size)} -> #{inspect(snap.ets_size)}")
    end
  end
end