# Runs the forward demo (NEW execution) and writes the independent evidence
# bundle + provenance graph under output/. Also emits the adversarial-style
# results file.
alias TiannaraOS.Provenance.{Demo, Source, Verifier, Canon}

root = Path.expand("..", __DIR__)

# source identity: pin the real T0 repo this project lives in, plus the
# forward_provenance source manifest (so the executed code is byte-pinned).
lib_files =
  Path.wildcard(Path.join(root, "lib/**/*.ex"))
  |> Enum.map(fn p -> {Path.relative_to(p, root), File.read!(p)} end)

source =
  Source.capture(
    cwd: Path.expand("..", root),
    source_files: lib_files
  )

contract_bytes = File.read!(Path.join(root, "contracts/tia_fp_forward_entropy_stability_v1.yaml"))

demo =
  Demo.run(
    experiment_id: "fps_001_forward_entropy_stability",
    campaign_id: "fp_demo_2026_09_08",
    seed: 42,
    sample_count: 1000,
    gate_std_dev: 0.05,
    output_dir: Path.join(root, "output/demo_fps_001"),
    source: source,
    contract_bytes: contract_bytes,
    demo_id: "fps_001"
  )

ver =
  Verifier.verify(Path.join(root, "output/demo_fps_001/bundle"))

summary = %{
  "demo_id" => demo["demo_id"],
  "experiment_id" => demo["experiment_id"],
  "execution_id" => demo["execution"]["execution_id"],
  "seed" => demo["execution"]["seed"],
  "source_commit" => source["fields"]["commit"],
  "source_tree" => source["fields"]["tree"],
  "source_manifest_hash" => source["fields"]["source_manifest_hash"],
  "contract_object_hash" => demo["contract"]["object_hash"],
  "metric" => %{
    "mean" => demo["metric"]["value"]["mean"],
    "std_dev" => demo["metric"]["value"]["std_dev"],
    "corpus_sha256" => demo["metric"]["corpus_sha256"]
  },
  "certificate" => %{
    "certificate_id" => demo["certificate"]["certificate_id"],
    "decision" => demo["certificate"]["decision"],
    "certificate_hash" => demo["certificate"]["certificate_hash"]
  },
  "bundle_path" => Path.relative_to(demo["bundle"]["root"], root),
  "bundle_manifest_sha256" => demo["bundle"]["manifest_sha256"],
  "bundle_verification_status" => ver["status"],
  "verification_checks" => ver["checks"],
  "verification_edges" => ver["edges"]
}

File.mkdir_p!(Path.join(root, "output"))
File.write!(
  Path.join(root, "output/demo_fps_001_summary.json"),
  Canon.canon(summary)
)

IO.puts("== FORWARD DEMO COMPLETE ==")
IO.puts("execution_id:   #{summary["execution_id"]}")
IO.puts("metric:         mean #{summary["metric"]["mean"]} std #{summary["metric"]["std_dev"]}")
IO.puts("certificate:    #{summary["certificate"]["decision"]} / #{summary["certificate"]["certificate_id"]}")
IO.puts("bundle verify:  #{summary["bundle_verification_status"]}")
IO.puts("bundle path:    #{summary["bundle_path"]}")