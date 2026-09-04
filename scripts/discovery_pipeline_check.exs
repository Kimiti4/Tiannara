# scripts/discovery_pipeline_check.exs
# Discovery pipeline audit — instrument-first build.
#
#   mix run scripts/discovery_pipeline_check.exs          # audit only
#   SEED=1 mix run scripts/discovery_pipeline_check.exs   # seed epistemic pressure first
#
# Marks: 🟢 growing · 🔵 present/flat · 🟡 regressed · ⚪ uninstrumented · 🔴 error

Application.ensure_all_started(:tiannara)

if System.get_env("SEED") == "1" do
  IO.puts("\n[check] SEED=1 — injecting epistemic pressure into the world model...")
  manifest = Tiannara.Discovery.EpistemicSeeder.seed_battery()

  IO.puts(
    "[check] manifest: entities_created=#{manifest.entities_created} " <>
      "gaps_from_seed=#{length(manifest.gaps_from_seed)} " <>
      "contradictions_from_seed=#{length(manifest.contradictions_from_seed)}"
  )
end

snapshot = Tiannara.Discovery.PipelineTelemetry.snapshot()
stages = Tiannara.Discovery.PipelineTelemetry.stages()

marks = %{
  growing: "\u{1F7E2}",
  present: "\u{1F535}",
  flat: "\u{1F535}",
  regressed: "\u{1F7E1}",
  uninstrumented: "\u26AA",
  error: "\u{1F534}"
}

IO.puts("\n=== Discovery Pipeline Audit (#{snapshot.sampled_at}) ===")
IO.puts("sample ##{snapshot.sample_count} — started #{snapshot.started_at}\n")

case snapshot.seeded_inputs do
  nil ->
    IO.puts("seeded_inputs: N/A (no epistemic seed read)\n")

  seeded ->
    IO.puts("seeded_inputs (epistemic-seed pipeline inputs): #{seeded}\n")
end

Enum.each(stages, fn stage ->
  info = snapshot.stages[stage]
  mark = marks[info.status] || "?"

  stall =
    if snapshot.first_stall && snapshot.first_stall.stage == stage,
      do: "  ◀ FIRST STALL",
      else: ""

  value =
    cond do
      is_number(info.value) -> "#{info.value}"
      info.status == :error -> inspect(info.value)
      true -> "—"
    end

  value =
    if stage == :knowledge_integration and is_integer(info.value) and
         is_integer(snapshot.seeded_inputs) do
      "#{info.value} earned (of #{info.value + snapshot.seeded_inputs} observable)"
    else
      value
    end

  IO.puts(
    "  #{mark} #{String.pad_trailing("#{stage}", 24)} #{String.pad_trailing("#{info.status}", 14)} #{value}#{stall}"
  )
end)

uninstrumented = snapshot.uninstrumented
growing_count = Enum.count(stages, fn s -> snapshot.stages[s].status == :growing end)
total = length(stages)

verdict =
  cond do
    uninstrumented != [] ->
      "\u26AA #{length(uninstrumented)} stage(s) uninstrumented — wire counters for: #{Enum.join(uninstrumented, ", ")}"

    snapshot.first_stall != nil ->
      "◀ First stall: #{snapshot.first_stall.stage} (#{snapshot.first_stall.status}) — investigate before the 72h run"

    growing_count >= total - 1 ->
      "\u{1F7E2} #{growing_count}/#{total} stages growing — pipeline eligible for the 72h soak run"

    true ->
      "\u{1F7E1} Mixed state (#{growing_count}/#{total} growing) — seed and re-run: SEED=1 mix run scripts/discovery_pipeline_check.exs"
  end

IO.puts("\nVERDICT: #{verdict}")

IO.puts("""

Note: grey (:uninstrumented) cells are honest gaps in counter coverage, not
failures. A stage with no counter cannot move; wiring the counter (or the
thin autonomous stages) is the follow-up work the audit names.
""")
