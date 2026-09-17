# INDEPENDENT verification: reads ONLY the evidence bundle bytes.
# Run in a fresh VM: `mix run scripts/verify_demo.exs <bundle_dir>`.
# Emits output/verification_result.json with the full verdict tree.
alias TiannaraOS.Provenance.Verifier

[arg] = System.argv() || raise "usage: mix run scripts/verify_demo.exs <bundle_dir>"
root = Path.expand("..", __DIR__)
bundle_dir = Path.expand(arg, root)

result = Verifier.verify(bundle_dir)

out = %{
  "bundle_dir" => Path.relative_to(bundle_dir, root),
  "bundle_id" => result["bundle_id"],
  "status" => result["status"],
  "checks" => result["checks"],
  "edges" => result["edges"],
  "verdict_delivered_at" => DateTime.utc_now() |> DateTime.to_iso8601()
}

File.mkdir_p!(Path.join(root, "output"))
File.write!(
  Path.join(root, "output/verification_result.json"),
  TiannaraOS.Provenance.Canon.canon(out)
)

IO.puts("== INDEPENDENT BUNDLE VERIFICATION ==")
IO.puts("bundle_id: #{out["bundle_id"]}")
IO.puts("status:    #{out["status"]}")
for c <- result["checks"] do
  IO.puts("  [check] #{c["check"]}: #{c["status"]}")
end
for e <- result["edges"] do
  IO.puts("  [edge ] #{e["edge"]}: #{e["status"]}")
end

# Termination contract: do not certify unless ACCEPT
unless result["status"] == "ACCEPT" do
  IO.puts("FAIL: bundle did not verify to ACCEPT; no certification permitted.")
  System.halt(1)
end