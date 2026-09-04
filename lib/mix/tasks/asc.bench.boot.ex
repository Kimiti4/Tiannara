defmodule Mix.Tasks.Asc.Bench.Boot do
  use Mix.Task

  @moduledoc """
  ASC AE-001 benchmark: warm-boot latency of the ASC Core Supervisor tree.

  Measures two views of the same boot:
    - total:  real `Tiannara.ASC.Core.Supervisor` start/stop (authoritative)
    - per-child: sequential replay of the exact `init/1` children under a
      scratch supervisor (bottleneck attribution)

  Usage:
    mix asc.bench.boot --n 20 --warmup 2 --out priv/asc/missions/ASC-AE-001/baseline.eterm

  Honors the `ASC_BOOT_INSTRUMENT=1` env flag (instrumentation enabled).
  Never boots the full application; only the ASC core tree is exercised.
  """

  @default_out "priv/asc/missions/ASC-AE-001/baseline.eterm"

  @impl true
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args,
        strict: [n: :integer, warmup: :integer, out: :string, help: :boolean]
      )

    if opts[:help] do
      IO.puts(@moduledoc)
      exit({:shutdown, 0})
    end

    n = opts[:n] || 20
    warmup = opts[:warmup] || 2
    out = opts[:out] || @default_out

    instrument? = System.get_env("ASC_BOOT_INSTRUMENT") == "1"

    IO.puts("=== ASC AE-001 warm-boot benchmark (n=#{n}, warmup=#{warmup}, instrument=#{instrument?}) ===")

    stop_stale()

    for _ <- 1..warmup do
      boot_real()
    end

    boots = for _ <- 1..n, do: boot_real()
    totals = Enum.map(boots, &elem(&1, 0))
    attributions = for _ <- 1..n, do: boot_replay()

    total_stats = stats(totals)

    child_keys = attributions |> List.first() |> Map.keys() |> Enum.sort()

    timings =
      Enum.map(child_keys, fn child ->
        samples = Enum.map(attributions, &Map.fetch!(&1, child))
        med = percentile(samples, 50)
        %{
          child: child,
          median_ms: med,
          mean_ms: mean(samples),
          min_ms: Enum.min(samples),
          max_ms: Enum.max(samples)
        }
      end)

    sum_median = timings |> Enum.map(& &1.median_ms) |> Enum.sum()

    memory_before = :erlang.memory(:total)
    {_, memory_after} = List.last(boots)
    memory_mb = round(memory_after / 1_048_576)
    memory_delta_mb = round((memory_after - memory_before) / 1_048_576)

    result = %{
      target: "Tiannara.ASC.Core.Supervisor",
      n: n,
      warmup: warmup,
      instrument: instrument?,
      p50_ms: total_stats.p50,
      p95_ms: total_stats.p95,
      mean_ms: total_stats.mean,
      min_ms: total_stats.min,
      max_ms: total_stats.max,
      sum_child_median_ms: Float.round(sum_median, 2),
      memory_mb: memory_mb,
      memory_delta_mb: memory_delta_mb,
      timings: Enum.sort_by(timings, & &1.median_ms, :desc)
    }

    meta = %{
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      git_head: git_head(),
      elixir: System.version(),
      otp: System.otp_release()
    }

    File.mkdir_p!(Path.dirname(out))
    File.write!(out, :erlang.term_to_binary({result, meta}))

    IO.puts("--- baseline ---")
    IO.puts("p50 Boot Latency: #{result.p50_ms} ms")
    IO.puts("p95 Boot Latency: #{result.p95_ms} ms")
    IO.puts("Memory Footprint: #{result.memory_mb} MB (delta #{result.memory_delta_mb} MB)")
    IO.puts("Sum(child medians): #{result.sum_child_median_ms} ms (vs total p50 #{result.p50_ms} ms)")
    IO.puts("Top bottlenecks (sequential attribution):")

    result.timings
    |> Enum.each(fn t ->
      IO.puts("  - #{t.child}: #{Float.round(t.median_ms, 2)} ms (mean #{Float.round(t.mean_ms, 2)}, max #{Float.round(t.max_ms, 2)})")
    end)

    IO.puts("wrote: #{out}")
  end

  defp boot_real do
    t0 = System.monotonic_time(:microsecond)
    {:ok, pid} = Tiannara.ASC.Core.Supervisor.start_link()
    t1 = System.monotonic_time(:microsecond)
    Supervisor.stop(pid, :normal)
    {Float.round((t1 - t0) / 1000, 2), :erlang.memory(:total)}
  end

  defp boot_replay do
    {:ok, {_sup_opts, children}} = Tiannara.ASC.Core.Supervisor.init([])
    {:ok, sup} = Supervisor.start_link([], strategy: :rest_for_one)

    samples =
      Enum.map(children, fn child ->
        id = child_id(child)
        t0 = System.monotonic_time(:microsecond)
        {:ok, _pid} = Supervisor.start_child(sup, child)
        t1 = System.monotonic_time(:microsecond)
        {id, Float.round((t1 - t0) / 1000, 2)}
      end)

    Supervisor.stop(sup, :normal)
    Map.new(samples)
  end

  defp child_id(child) do
    case Supervisor.child_spec(child, []) do
      %{id: id} -> id
      other -> inspect(other)
    end
  end

  defp stop_stale do
    if Process.whereis(Tiannara.ASC.Core.Supervisor) do
      Supervisor.stop(Process.whereis(Tiannara.ASC.Core.Supervisor), :normal)
    end

    if Process.whereis(Tiannara.ASC.Core.WorkerSupervisor) do
      Supervisor.stop(Process.whereis(Tiannara.ASC.Core.WorkerSupervisor), :normal)
    end

    if Process.whereis(Tiannara.ASC.Core.Coordinator) do
      GenServer.stop(Process.whereis(Tiannara.ASC.Core.Coordinator), :normal)
    end
  end

  defp stats(samples) do
    %{
      p50: percentile(samples, 50),
      p95: percentile(samples, 95),
      mean: mean(samples),
      min: Enum.min(samples),
      max: Enum.max(samples)
    }
  end

  defp percentile(samples, p) when p > 0 and p <= 100 do
    sorted = Enum.sort(samples)
    k = max(1, ceil(length(sorted) * p / 100))
    Enum.at(sorted, k - 1) |> Float.round(2)
  end

  defp mean(samples) do
    Float.round(Enum.sum(samples) / length(samples), 2)
  end

  defp git_head do
    case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
      {out, 0} -> String.trim(out)
      _ -> "unknown"
    end
  end
end