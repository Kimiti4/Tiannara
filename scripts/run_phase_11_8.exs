# Coordinator Script for Phase 11.8 Orbit Classification
IO.puts("Initiating Phase 11.8: Orbit Classification & Regenerative Dynamics...")

case System.cmd("python", ["scripts/tiannara_ucc/tensors/classify_orbits.py"]) do
  {output, 0} ->
    IO.puts("✅ Success:")
    IO.puts(output)
  {error_msg, code} ->
    IO.puts("❌ Error (exit code #{code}):")
    IO.puts(error_msg)
end
