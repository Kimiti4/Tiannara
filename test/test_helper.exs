# NOTE: do NOT set trace: true here — ExUnit.Runner.get_timeout/2 returns
# :infinity whenever config.trace is enabled, silently disabling both the
# default timeout and every @tag timeout (this is what let Layer65D grind
# for hours instead of failing at 180s). Use `mix test --trace` ad hoc when
# per-test progress is wanted.
ExUnit.start(seed: 0, timeout: 30_000, max_cases: 4, assert_receive_timeout: 5_000)

Application.put_env(:tiannara, :test_mode, true)

# D-A5: wipe ONLY this run's persistence roots. Cross-VM-unique ids from
# config/test.exs mean we must never rm_rf the parent test_data/dets tree
# (that would destroy concurrent runs). Residue from other run ids is inert
# and never becomes input to this run.
test_data_path = Application.get_env(:tiannara, :dets_base_path, "./test_data/dets")
storage_base = Application.get_env(:tiannara, :storage_base, "./test_data/storage")

unless is_binary(test_data_path) and test_data_path != "" do
  raise "D-A5 isolation: :dets_base_path missing/empty — refusing to start suite"
end

# Observable cleanup: fail loudly if the run root cannot be established.
case File.rm_rf(test_data_path) do
  {:ok, _} ->
    :ok

  {:error, reason, file} ->
    raise "D-A5 isolation: failed to wipe #{test_data_path} (#{inspect({reason, file})})"
end

File.mkdir_p!(test_data_path)

# Guard: refuse a path that is not under test_data (cross-context leak).
unless String.contains?(test_data_path, "test_data") do
  raise "D-A5 isolation: dets_base_path not under test_data: #{inspect(test_data_path)}"
end

if is_binary(storage_base) and storage_base != "" do
  case File.rm_rf(storage_base) do
    {:ok, _} ->
      :ok

    {:error, reason, file} ->
      raise "D-A5 isolation: failed to wipe storage base #{storage_base} (#{inspect({reason, file})})"
  end

  File.mkdir_p!(storage_base)
  # Re-create the test context segment so app-started writers (checkpointer)
  # survive the intentional wipe of this run's root.
  File.mkdir_p!(Path.join([storage_base, "test", "checkpoints"]))
end

ExUnit.after_suite(fn _results ->
  # Best-effort teardown of THIS run only; failure after suite must not
  # invent a pass, but also must not raise over already-collected results.
  _ = File.rm_rf(test_data_path)

  if is_binary(storage_base) and storage_base != "" do
    _ = File.rm_rf(storage_base)
  end
end)
