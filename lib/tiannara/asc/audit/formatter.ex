defmodule Tiannara.ASC.Audit.Formatter do
  @moduledoc """
  ExUnit formatter that classifies every test result for the capability
  audit and writes machine-readable + Markdown reports. Usage:
  mix asc.audit [paths to scope the run]
  """

  use GenServer

  def init(_opts) do
    {:ok,
     %{
       out: System.get_env("ASC_AUDIT_OUT", "priv/audit"),
       manifest: System.get_env("ASC_AUDIT_MANIFEST", "test/asc/capability_manifest.exs"),
       rows: [],
       seen_modules: MapSet.new(),
       started_us: System.monotonic_time(:microsecond)
     }}
  end

  def handle_cast({:suite_started, _opts}, state), do: {:noreply, suite_started(state)}
  def handle_cast({:suite_finished, _times_us}, state), do: {:noreply, suite_finished(state)}
  def handle_cast({:case_started, _case}, state), do: {:noreply, case_started(state)}
  def handle_cast({:module_started, _module}, state), do: {:noreply, module_started(state)}
  def handle_cast({:case_finished, test_case}, state), do: {:noreply, case_finished(state, test_case)}
  def handle_cast({:module_finished, test_module}, state), do: {:noreply, module_finished(state, test_module)}
  def handle_cast({:test_started, test}, state), do: {:noreply, test_started(state, test)}
  def handle_cast({:test_finished, test}, state), do: {:noreply, test_finished(state, test)}
  def handle_cast(_, state), do: {:noreply, state}

  def suite_started(state), do: state

  def test_started(state, test),
    do: %{state | seen_modules: MapSet.put(state.seen_modules, test.module)}

  def test_finished(state, test) do
    row = %{
      module: inspect(test.module),
      test: to_string(test.name),
      time_ms: test.time |> Kernel./(1000) |> Float.round(2),
      classification: classify(test.state)
    }

    %{state | rows: [row | state.rows]}
  end

  def case_started(state), do: state

  def case_finished(state, _case), do: state

  def module_started(state), do: state

  def module_finished(state, _module), do: state

  def suite_finished(state) do
    duration_ms = (System.monotonic_time(:microsecond) - state.started_us) |> div(1000)
    rows = Enum.reverse(state.rows)
    missing = missing_from_manifest(state.manifest, state.seen_modules)
    File.mkdir_p!(state.out)

    term_path = Path.join(state.out, "milestone_b_audit.eterm")
    md_path = Path.join(state.out, "milestone_b_audit.md")

    report = %{generated_at: DateTime.utc_now(), duration_ms: duration_ms, rows: rows, missing: missing}
    File.write!(term_path, :erlang.term_to_binary(report))
    File.write!(md_path, render_markdown(report))

    IO.puts("\n== ASC AUDIT ==")
    IO.puts("report: #{md_path}")
    IO.puts("term:   #{term_path}")

    for class <- [:pass, :fail, :blocked, :disconnected, :environment] do
      n = Enum.count(rows, &(&1.classification == class))
      IO.puts("#{String.upcase(to_string(class))}: #{n}")
    end

    IO.puts("MISSING: #{length(missing)}")
    state
  end

  defp classify(nil), do: :pass
  defp classify(:invalid), do: :fail
  defp classify({:failed, failures}) when is_list(failures) do
    case failures do
      [%{reason: reason} | _] -> classify_reason(reason)
      [{_kind, reason, _stack} | _] -> classify_reason(reason)
      _ -> :fail
    end
  end
  defp classify({:skipped, _reason}), do: :environment
  defp classify({:excluded, _reason}), do: :environment
  defp classify({_kind, reason, _stack}), do: classify_reason(reason)
  defp classify(_), do: :fail

  defp classify_reason(%ExUnit.AssertionError{}), do: :fail
  defp classify_reason(%UndefinedFunctionError{}), do: :blocked
  defp classify_reason(%ExUnit.TimeoutError{}), do: :environment
  defp classify_reason(%File.Error{}), do: :environment

  defp classify_reason(%ArgumentError{message: msg}) do
    if msg =~ "unknown registry", do: :disconnected, else: :fail
  end

  defp classify_reason(%ErlangError{original: original})
       when original in [:enoent, :econnrefused, :etimedout],
       do: :environment

  defp classify_reason(:noproc), do: :disconnected
  defp classify_reason({:noproc, _}), do: :disconnected
  defp classify_reason(_), do: :fail

  defp missing_from_manifest(path, seen) do
    if File.exists?(path) do
      {entries, _} = Code.eval_file(path)

      for %{capability: cap, module: mod} <- entries,
          not MapSet.member?(seen, mod),
          do: %{capability: cap, module: inspect(mod), classification: :missing}
    else
      []
    end
  end

  defp render_markdown(%{rows: rows, missing: missing, duration_ms: ms}) do
    header = "| Module | Test | ms | Classification |\n|---|---|---|---|\n"

    body =
      Enum.map_join(rows, "\n", fn r ->
        "| #{r.module} | #{r.test} | #{r.time_ms} | #{r.classification |> to_string() |> String.upcase()} |"
      end)

    missing_body =
      Enum.map_join(missing, "\n", fn m ->
        "| #{m.module} | (capability: #{m.capability}) | - | MISSING |"
      end)

    "# ASC Milestone B Audit\n\nDuration: #{ms} ms\n\n#{header}#{body}\n\n## Missing\n\n#{header}#{missing_body}\n"
  end
end