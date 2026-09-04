# F2 closer: does the WorkflowEngine put_in crash signature appear in a log?
# --no-start mandatory; read-only.
#
# Usage:
#   mix run --no-start scripts/check_f2_closed.exs <log> [--since ISO_TIMESTAMP]
#
# Without --since: reports the signature count for the whole log. PASS (:closed)
# requires count == 0 AND a fresh-image log (a pre-fix log can only ever report
# :pending - the old BEAM loaded the buggy code).
#
# With --since: counts only lines whose virtual ISO timestamp is >= the given
# UTC timestamp (log lines are HH:MM:SS only; enrichment re-adds the date).
# Use it on a POST-FIX soak log with --since <post-fix soak start>.
#
# Status: :closed if signature count is 0, :pending otherwise (recorded, not
# filtered - the crash lines remain in the evidence trail).

[log_path | rest] = System.argv()

since =
  case Enum.find_index(rest, &(&1 == "--since")) do
    nil -> nil
    i -> Enum.at(rest, i + 1)
  end

if is_nil(log_path), do: raise("usage: mix run --no-start scripts/check_f2_closed.exs <log> [--since ISO]")
if not File.exists?(log_path), do: raise("log not found: #{log_path}")

defmodule F2Closer do
  @signature ~r/^\*\* \(ArgumentError\) could not put\/update key "step_execute" on a nil value/

  def run(log_path, since) do
    {matching, total} =
      File.stream!(log_path)
      |> Stream.map(&String.trim/1)
      |> Stream.transform(%{day: 15, last_h: nil, last_iso: nil}, fn line, st ->
        case Regex.run(~r/^(\d{2}):(\d{2}):(\d{2})\.?\d*/, line) do
          [_, h, m, s] ->
            day =
              if st.last_h != nil and String.to_integer(h) < st.last_h,
                do: st.day + 1,
                else: st.day

            iso = "2026-08-#{String.pad_leading(Integer.to_string(day), 2, "0")}T#{h}:#{m}:#{s}"
            {[{line, iso}], %{day: day, last_h: String.to_integer(h), last_iso: iso}}

          nil ->
            {[{line, st.last_iso}], st}
        end
      end)
      |> Enum.reduce({0, 0}, fn {line, iso}, {matching, total} ->
        matches = Regex.match?(@signature, line) and (is_nil(since) or (iso != nil and iso >= since))
        {matching + if(matches, do: 1, else: 0), total + 1}
      end)

    {matching, total}
  end
end

{matching, total} = F2Closer.run(log_path, since)

status = if matching == 0, do: :closed, else: :pending

IO.puts("""
F2 CLOSER
log:     #{log_path}
since:   #{since || "(entire log)"}
signature matches: #{matching} / #{total} lines
status:  #{status}
note:    #{if status == :closed,
  do: "no WorkflowEngine put_in crash signature present; F2 closed on this image",
  else: "signature present; soak ran the OLD image (soak_runtime_patched: false). PASS requires a post-fix image log with --since set."}
""")