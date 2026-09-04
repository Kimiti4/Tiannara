Code.require_file("../test/test_helper.exs", __ENV__.file)
Code.require_file("../test/support/phase3_test_helpers.ex", __ENV__.file)

defmodule Phase3ValidationRunner do
  @moduletag timeout: 300_000

  def run_all do
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Phase 3 Validation Campaign")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("")

    results = %{
      property: run_category("Property-Based Tests", "test/tiannara/world/property/*_test.exs"),
      integration: run_category("Integration Tests", "test/tiannara/world/integration/*_test.exs"),
      chaos: run_category("Chaos/Recovery Tests", "test/tiannara/world/chaos/*_test.exs"),
      epistemic: run_category("Epistemic Tests", "test/tiannara/world/epistemic/*_test.exs")
    }

    IO.puts("")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("CAMPAIGN SUMMARY")
    IO.puts("=" |> String.duplicate(60))

    Enum.each(results, fn {category, %{passed: passed, failed: failed, total: total, time: time}} ->
      status = if failed == 0, do: "PASS", else: "FAIL"
      IO.puts("#{category |> Atom.to_string() |> String.pad_trailing(20)} #{status}  #{passed}/#{total} passed in #{time}ms")
    end)

    total = results |> Enum.map(fn {_, %{total: t}} -> t end) |> Enum.sum()
    failed_total = results |> Enum.map(fn {_, %{failed: f}} -> f end) |> Enum.sum()

    IO.puts("")
    IO.puts("Total: #{total} tests, #{total - failed_total} passed, #{failed_total} failed")
    IO.puts("Overall: #{if failed_total == 0, do: "ALL PASSED", else: "SOME FAILED"}")
  end

  defp run_category(name, pattern) do
    IO.puts("--- #{name} ---")
    {micro, result} = :timer.tc(fn ->
      case Code.eval_string("Path.wildcard(~c\"#{pattern}\")") do
        {files, _} ->
          Enum.reduce(files, {0, 0, 0}, fn file, {pass, fail, total} ->
            IO.puts("  Running: #{Path.basename(file)}")
            {micro_file, :ok} = :timer.tc(fn ->
              Code.require_file(file)
            end)
            IO.puts("    Completed in #{div(micro_file, 1000)}ms")
            {pass + 1, fail, total + 1}
          end)

        error ->
          IO.puts("  Error loading files: #{inspect(error)}")
          {0, 1, 1}
      end
    end)

    time_ms = div(micro, 1000)
    {passed, failed, total} = result

    IO.puts("")
    %{passed: passed, failed: failed, total: total, time: time_ms}
  end
end

Phase3ValidationRunner.run_all()
