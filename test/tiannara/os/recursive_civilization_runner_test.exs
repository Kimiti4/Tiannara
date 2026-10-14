defmodule TiannaraOS.RecursiveCivilizationRunnerTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.RecursiveCivilizationRunner

  setup do
    output_dir =
      Path.join(System.tmp_dir!(), "runner_prov_#{:erlang.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(output_dir) end)
    %{output_dir: output_dir}
  end

  test "history rows carry resolvable manifest_id and certificate_id with honest statuses",
       %{output_dir: output_dir} do
    assert {:ok, histories} =
             RecursiveCivilizationRunner.execute(1, %{
               output_dir: output_dir,
               episodes_per_generation: 5,
               enable_adaptation: false
             })

    [history] = histories

    assert is_binary(history.manifest_id)
    assert String.starts_with?(history.manifest_id, "MANIFEST-")
    assert is_binary(history.certificate_id)
    assert String.starts_with?(history.certificate_id, "CERT-")

    # Manifest persisted at run start and resolvable from the recorded id
    manifest_path = Path.join(output_dir, "constitution_manifest.json")
    assert File.exists?(manifest_path)

    manifest =
      TiannaraOS.Kernel.ConstitutionManifest.from_json(File.read!(manifest_path))

    assert manifest.manifest_id == history.manifest_id
    assert String.length(manifest.combined_hash) == 64

    # Per-generation attestation binds the history row to the certificate
    attestation_path = Path.join(output_dir, "constitution_attestations.jsonl")
    assert File.exists?(attestation_path)

    [attestation] =
      attestation_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)

    assert attestation["manifest_id"] == history.manifest_id
    assert attestation["certificate_id"] == history.certificate_id
    assert String.length(attestation["certificate_hash"]) == 64

    # Harness performs no real verification - statuses must stay honest
    assert attestation["certification_level"] == "minimal"

    # CSV durably carries both provenance columns
    csv = File.read!(Path.join(output_dir, "generation_history.csv"))
    [header, row] = csv |> String.split("\n", trim: true) |> Enum.take(2)

    assert String.contains?(header, "manifest_id")
    assert String.contains?(header, "certificate_id")
    assert String.contains?(row, history.manifest_id)
    assert String.contains?(row, history.certificate_id)
  end
end
