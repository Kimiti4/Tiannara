# Parallel OOM track: read-only analysis of erl_crash.dump (BEAM text dump).
# --no-start mandatory; never boots anything.
#
# Usage:
#   mix run --no-start scripts/analyze_oom_dump.exs <erl_crash.dump> [out.txt]
#
# Extracts: VM memory summary, allocated areas, process count, and per-process
# attribution (total memory, term heap vs binary refs, queue length, reductions)
# to support the F4 root-cause hypothesis. The `Memory:` field includes binary
# references held by the process; heap fields give the live-term side.

[log_path, out_path | _] = System.argv()

if is_nil(log_path), do: raise("usage: mix run --no-start scripts/analyze_oom_dump.exs <erl_crash.dump> [out.txt]")
if not File.exists?(log_path), do: raise("dump not found: #{log_path}")

defmodule OomAnalyzer do
  def analyze(path) do
    result =
      File.stream!(path)
      |> Enum.reduce(
        %{section: nil, memory: %{}, procs: [], current_proc: nil, system_version: []},
        fn line, acc ->
          line = String.trim(line)

          cond do
            String.starts_with?(line, "=memory") ->
              %{acc | section: :memory}

            String.starts_with?(line, "=proc:<") ->
              pid = line |> String.trim_leading("=proc:<") |> String.trim_trailing(">")
              %{acc | section: :procs, procs: push(acc), current_proc: %{pid: pid, name: "?", memory: 0, stack: 0, old_heap: 0, heap_unused: 0, old_heap_unused: 0, bin_vheap: 0, old_bin_vheap: 0, fragments: 0, queue: -1, func: "?", reductions: 0}}

            String.starts_with?(line, "=system_version") ->
              %{acc | section: :sysver}

            String.starts_with?(line, "=") ->
              %{acc | section: :other}

            true ->
              case acc.section do
                :memory -> %{acc | memory: Map.put(acc.memory, first_kv(line), parse_bytes(line))}
                :procs -> procs_line(acc, line)
                :sysver -> if length(acc.system_version) < 5, do: %{acc | system_version: [line | acc.system_version]}, else: acc
                _ -> acc
              end
          end
        end
      )

    %{result | procs: push(result) |> Enum.reverse()}
  end

  # push the current (already completed) proc onto the collected list
  defp push(acc) do
    case acc.current_proc do
      nil -> acc.procs
      p -> [p | acc.procs]
    end
  end

  defp procs_line(acc, line) do
    cond do
      acc.current_proc == nil ->
        acc

      String.starts_with?(line, "Memory:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :memory, parse_bytes(line))}

      String.starts_with?(line, "Name:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :name, line |> String.replace_prefix("Name:", "") |> String.trim())}

      String.starts_with?(line, "Reductions:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :reductions, parse_bytes(line))}

      String.starts_with?(line, "Stack+heap:") or String.starts_with?(line, "StackHeap:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :stack, parse_bytes(line))}

      String.starts_with?(line, "OldHeap:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :old_heap, parse_bytes(line))}

      String.starts_with?(line, "Heap unused:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :heap_unused, parse_bytes(line))}

      String.starts_with?(line, "OldHeap unused:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :old_heap_unused, parse_bytes(line))}

      String.starts_with?(line, "BinVHeap:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :bin_vheap, parse_bytes(line))}

      String.starts_with?(line, "OldBinVHeap:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :old_bin_vheap, parse_bytes(line))}

      String.starts_with?(line, "Heap fragment data:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :fragments, parse_bytes(line))}

      String.starts_with?(line, "Message queue length:") ->
        %{acc | current_proc: Map.put(acc.current_proc, :queue, parse_bytes(line))}

      String.starts_with?(line, "current_function:") ->
        func = line |> String.replace_prefix("current_function:", "") |> String.trim()
        %{acc | current_proc: Map.put(acc.current_proc, :func, func)}

      true ->
        acc
    end
  end

  defp first_kv(line) do
    case Regex.run(~r/^(\w+):/, line) do
      [_, k] -> k
      _ -> line
    end
  end

  defp parse_bytes(line) do
    case Regex.run(~r/(\d+)/, line) do
      [_, n] -> String.to_integer(n)
      _ -> 0
    end
  end
end

res = OomAnalyzer.analyze(log_path)

procs = Enum.sort_by(res.procs, & &1.memory, :desc) |> Enum.take(25)
total_proc_mem = Enum.reduce(res.procs, 0, &(&2 + &1.memory))

mb = fn b -> Float.round(b / 1_048_576, 1) end

suspects = [
  "RepairLibrary",
  "ObservationBuffer",
  "ResearchQueue",
  "AgencyLoop",
  "DiscoveryScheduler",
  "ResearchDirector",
  "ExecutiveMemory",
  "UnifiedRealityGraph"
]

suspect_rows =
  Enum.map(suspects, fn s ->
    p = Enum.find(res.procs, &String.contains?(&1.name, s))
    if p do
      term = p.stack + p.old_heap + p.bin_vheap + p.old_bin_vheap + p.fragments
      "  #{p.pid}  #{s}  mem=#{mb.(p.memory)} MB  term_heap=#{mb.(term)} MB  binary_refs~#{mb.(max(p.memory - term, 0))} MB  q=#{p.queue}  red=#{p.reductions}"
    else
      "  -  #{s}  NOT FOUND in dump"
    end
  end)

heap_rows =
  Enum.map(procs, fn p ->
    heap = p.stack + p.old_heap
    term = heap + p.bin_vheap + p.old_bin_vheap + p.fragments
    unused = p.heap_unused + p.old_heap_unused
    "  #{p.pid}  #{p.name}  mem=#{mb.(p.memory)} MB  heap=#{mb.(heap)} MB (unused #{mb.(unused)} MB)  bin~#{mb.(max(p.memory - term, 0))} MB  q=#{p.queue}  red=#{p.reductions}"
  end)

summary = """
OOM DUMP ANALYSIS (read-only, F4 parallel track)
dump: #{log_path}

--- VM memory (bytes) ---
#{Enum.map_join(res.memory, "\n", fn {k, v} -> "  #{k}: #{mb.(v)} MB" end)}

--- processes ---
total processes: #{length(res.procs)}
sum process memory: #{mb.(total_proc_mem)} MB

--- suspect processes at death (Track A/C attribution) ---
#{Enum.join(suspect_rows, "\n")}

--- largest 25 processes by total memory ---
#{Enum.join(heap_rows, "\n")}

--- interpretation (Track A/B/C) ---
- `mem` = `Memory:` field: total process memory incl. referenced binaries.
- `term_heap` = Stack+heap + OldHeap + BinVHeap + OldBinVHeap + heap fragments.
- `binary_refs` = mem minus term_heap: binaries referenced from the process's
  state (off-heap). A large gap means binary retention, not live terms.
- `q` = message queue length at death (0 = no mailbox pressure; >0 = producer
  outruns consumer).
- OldHeap unused ~= old heap: means large transient messages caused heap
  growth that was never reclaimed (generation-sweep bloat).
- Correlate with DiscoveryScheduler timeouts from the final stack trace.
  This is evidence for F4 attribution, not a verdict.
"""

IO.puts(summary)

if out_path do
  File.mkdir_p!(Path.dirname(out_path))
  File.write!(out_path, summary)
  IO.puts("wrote: #{out_path}")
end