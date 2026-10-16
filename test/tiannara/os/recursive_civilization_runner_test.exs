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
               authorized: true,
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

  # ──────────────────────────────────────────────
  # Phase D step 1: authorization, bounding, machine-readable labels
  # ──────────────────────────────────────────────

  describe "explicit authorization gate (Phase D)" do
    test "execute without authorized: true raises ArgumentError", %{output_dir: output_dir} do
      assert_raise ArgumentError, ~r/requires explicit authorization/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          output_dir: output_dir,
          episodes_per_generation: 5,
          enable_adaptation: false
        })
      end
    end

    test "zero episodes_per_generation raises ArgumentError (bounded runs)", %{
      output_dir: output_dir
    } do
      assert_raise ArgumentError, ~r/episodes_per_generation must be a positive integer/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 0
        })
      end
    end
  end

  describe "machine-readable stage evidence labels (Phase D step 1)" do
    test "run-level labels file is written, all simulated, never PASS", %{
      output_dir: output_dir
    } do
      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 enable_adaptation: false
               })

      labels_path = Path.join(output_dir, "stage_evidence_labels.json")
      assert File.exists?(labels_path)

      payload = labels_path |> File.read!() |> Jason.decode!()

      assert payload["run_authorized"] == true
      assert payload["certification_claim"] == "none"
      assert payload["bounded"]["generations"] == 1
      assert payload["bounded"]["episodes_per_generation"] == 5

      expected_stages = [
        "episode_generation",
        "theory_formation",
        "distributed_validation",
        "stage3_method_evolution",
        "stage4_institution_adaptation",
        "stage5_civilization_adaptation",
        "metrics_collection"
      ]

      assert Map.keys(payload["stage_evidence_labels"]) |> Enum.sort() ==
               Enum.sort(expected_stages)

      # Every label is :simulated until a stage's genuine wiring lands
      Enum.each(payload["stage_evidence_labels"], fn {_stage, label} ->
        assert label == "simulated"
      end)

      # The vocabulary never contains :pass — certification gates stay closed
      refute String.contains?(File.read!(labels_path), "\"pass\"")
    end

    test "attestation rows carry stage evidence labels and authorization record", %{
      output_dir: output_dir
    } do
      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 enable_adaptation: false
               })

      [attestation] =
        Path.join(output_dir, "constitution_attestations.jsonl")
        |> File.read!()
        |> String.split("\n", trim: true)
        |> Enum.map(&Jason.decode!/1)

      assert attestation["run_authorized"] == true
      assert attestation["bounded"]["generations"] == 1
      labels = attestation["stage_evidence_labels"]
      assert labels["stage3_method_evolution"] == "simulated"
      assert labels["stage4_institution_adaptation"] == "simulated"
      assert labels["stage5_civilization_adaptation"] == "simulated"
    end

    test "checkpoints carry stage evidence labels", %{output_dir: output_dir} do
      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 checkpoint_interval: 1,
                 enable_adaptation: false
               })

      checkpoint = Path.join(output_dir, "checkpoint_gen1.json")
      assert File.exists?(checkpoint)

      payload = checkpoint |> File.read!() |> Jason.decode!()
      assert payload["run_authorized"] == true
      assert payload["stage_evidence_labels"]["metrics_collection"] == "simulated"
    end
  end

  describe "stage_modes validation (Phase D staged wiring)" do
    test "requesting :evidence_backed for an unwired stage raises", %{
      output_dir: output_dir
    } do
      assert_raise ArgumentError, ~r/does not support :evidence_backed yet/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 5,
          stage_modes: %{stage3_method_evolution: :evidence_backed}
        })
      end
    end

    test "unknown stage_modes key raises", %{output_dir: output_dir} do
      assert_raise ArgumentError, ~r/Unknown stage_modes key/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 5,
          stage_modes: %{teleportation: :simulated}
        })
      end
    end

    test "invalid stage mode value raises", %{output_dir: output_dir} do
      assert_raise ArgumentError, ~r/Invalid stage mode/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 5,
          stage_modes: %{stage3_method_evolution: :banana}
        })
      end
    end

    test "explicit :simulated stage_modes are accepted and recorded", %{
      output_dir: output_dir
    } do
      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 enable_adaptation: false,
                 stage_modes: %{stage4_institution_adaptation: :simulated}
               })

      payload =
        Path.join(output_dir, "stage_evidence_labels.json")
        |> File.read!()
        |> Jason.decode!()

      assert payload["stage_modes"]["stage4_institution_adaptation"] == "simulated"
      assert payload["stage_evidence_labels"]["stage4_institution_adaptation"] == "simulated"
    end
  end
end
