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
          stage_modes: %{stage5_civilization_adaptation: :evidence_backed}
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

  # ──────────────────────────────────────────────
  # Phase D step 2: genuine Stage 3 wiring
  # ──────────────────────────────────────────────

  defp unique_institution(label) do
    String.to_atom("stage3_#{label}_#{System.unique_integer([:positive])}")
  end

  describe "genuine Stage 3 wiring (Phase D step 2)" do
    test "evidence_backed stage3 runs the genuine engine and persists machine-readable evidence",
         %{output_dir: output_dir} do
      inst_a = unique_institution(:genuine_a)
      inst_b = unique_institution(:genuine_b)

      assert {:ok, histories} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 institutions: [inst_a, inst_b],
                 stage_modes: %{stage3_method_evolution: :evidence_backed}
               })

      [history] = histories
      assert history.stage3_results_count == 2

      evidence_path = Path.join(output_dir, "stage3_evidence/generation_1.json")
      assert File.exists?(evidence_path)

      raw = File.read!(evidence_path)
      refute String.contains?(raw, "\"pass\"")

      payload = Jason.decode!(raw)
      assert payload["generation"] == 1
      assert payload["stage"] == "stage3_method_evolution"
      assert payload["stage_mode"] == "evidence_backed"
      assert payload["engine"] == "TiannaraOS.MethodEvolutionPipeline.execute_pipeline/3"
      assert payload["certification_claim"] == "none"
      assert payload["input_provenance"] =~ "harness_synthetic"

      assert length(payload["institutions"]) == 2

      for record <- payload["institutions"] do
        assert record["institution_id"] in [Atom.to_string(inst_a), Atom.to_string(inst_b)]
        assert record["episodes_analyzed"] == 5
        assert record["supporting_episodes"] > 0
        assert record["result_id"] =~ "method_evolution_"
        assert is_list(record["insufficient_data_metrics"])
        assert is_list(record["exclusions"])
      end
    end

    test "labels file records stage3 as evidence_backed with honest provenance", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:genuine_labels)

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 3,
                 institutions: [inst],
                 stage_modes: %{stage3_method_evolution: :evidence_backed}
               })

      payload =
        Path.join(output_dir, "stage_evidence_labels.json")
        |> File.read!()
        |> Jason.decode!()

      assert payload["stage_evidence_labels"]["stage3_method_evolution"] == "evidence_backed"
      assert payload["stage_evidence_labels"]["stage4_institution_adaptation"] == "simulated"

      assert payload["stage_provenance"]["stage3_method_evolution"] ==
               "genuine_engine_over_harness_synthetic_episodes"

      assert payload["stage_provenance"]["stage4_institution_adaptation"] ==
               "harness_fabricated_output"

      refute String.contains?(File.read!(Path.join(output_dir, "stage_evidence_labels.json")), "\"pass\"")
    end

    test "attestation rows carry the flipped label and provenance", %{output_dir: output_dir} do
      inst = unique_institution(:genuine_attest)

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 3,
                 institutions: [inst],
                 stage_modes: %{stage3_method_evolution: :evidence_backed}
               })

      [attestation] =
        Path.join(output_dir, "constitution_attestations.jsonl")
        |> File.read!()
        |> String.split("\n", trim: true)
        |> Enum.map(&Jason.decode!/1)

      assert attestation["stage_evidence_labels"]["stage3_method_evolution"] == "evidence_backed"

      assert attestation["stage_provenance"]["stage3_method_evolution"] ==
               "genuine_engine_over_harness_synthetic_episodes"
    end

    test "harness institution kernels are stopped after the stage (no process leaks)", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:genuine_cleanup)
      harness_id = :"stage6_harness_#{inst}"

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 3,
                 institutions: [inst],
                 stage_modes: %{stage3_method_evolution: :evidence_backed}
               })

      assert Process.whereis(harness_id) == nil
    end

    test "evidence_backed with adaptation disabled raises (labels never lie)", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:genuine_disabled)

      assert_raise ArgumentError, ~r/enable_adaptation: false/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 3,
          institutions: [inst],
          enable_adaptation: false,
          stage_modes: %{stage3_method_evolution: :evidence_backed}
        })
      end
    end

    test "evidence_backed with non-atom institutions raises", %{output_dir: output_dir} do
      assert_raise ArgumentError, ~r/non-empty\s+list of atom institution ids/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 3,
          institutions: ["not_an_atom"],
          stage_modes: %{stage3_method_evolution: :evidence_backed}
        })
      end
    end

    test "refuses to reuse an already-running harness kernel (fail-closed)", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:genuine_conflict)
      harness_id = :"stage6_harness_#{inst}"

      institution =
        TiannaraOS.ResearchInstitution.new(harness_id, :stage6_harness_world, 0)
        |> Map.put(:civilizational_memory, %{})

      {:ok, kernel_pid} = TiannaraOS.InstitutionKernel.start_link(harness_id, institution)

      on_exit(fn ->
        if Process.alive?(kernel_pid), do: Process.exit(kernel_pid, :kill)
      end)

      assert_raise ArgumentError, ~r/already running/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 3,
          institutions: [inst],
          stage_modes: %{stage3_method_evolution: :evidence_backed}
        })
      end
    end

    test "multi-generation genuine runs restart kernels cleanly each generation", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:genuine_multi)
      harness_id = :"stage6_harness_#{inst}"

      assert {:ok, histories} =
               RecursiveCivilizationRunner.execute(2, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 4,
                 institutions: [inst],
                 stage_modes: %{stage3_method_evolution: :evidence_backed}
               })

      assert length(histories) == 2
      assert Process.whereis(harness_id) == nil

      assert File.exists?(Path.join(output_dir, "stage3_evidence/generation_1.json"))
      assert File.exists?(Path.join(output_dir, "stage3_evidence/generation_2.json"))
    end
  end

  # ──────────────────────────────────────────────
  # Phase D step 3: genuine Stage 4 wiring
  # ──────────────────────────────────────────────

  describe "genuine Stage 4 wiring (Phase D step 3)" do
    test "evidence_backed stage4 runs the genuine engine and persists machine-readable evidence",
         %{output_dir: output_dir} do
      inst = unique_institution(:s4_genuine)

      assert {:ok, histories} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 institutions: [inst],
                 stage_modes: %{
                   stage3_method_evolution: :evidence_backed,
                   stage4_institution_adaptation: :evidence_backed
                 }
               })

      [history] = histories
      assert history.stage4_results_count >= 0

      evidence_path = Path.join(output_dir, "stage4_evidence/generation_1.json")
      assert File.exists?(evidence_path)

      raw = File.read!(evidence_path)
      refute String.contains?(raw, "\"pass\"")

      payload = Jason.decode!(raw)
      assert payload["generation"] == 1
      assert payload["stage"] == "stage4_institution_adaptation"
      assert payload["stage_mode"] == "evidence_backed"
      assert payload["engine"] == "TiannaraOS.Stage4InstitutionAdaptation.execute_stage_4/3"
      assert payload["input_provenance"] =~ "genuine_stage3_method_evolution_outputs"
      assert payload["certification_claim"] == "none"
      assert payload["evidence_mode"] == "evidence_backed"
      assert is_integer(payload["total_deferred"])
      assert is_integer(payload["total_adopted"])
      assert is_list(payload["deferral_reasons"])
    end

    test "labels file records stage3+stage4 as evidence_backed with honest provenance", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:s4_labels)

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 3,
                 institutions: [inst],
                 stage_modes: %{
                   stage3_method_evolution: :evidence_backed,
                   stage4_institution_adaptation: :evidence_backed
                 }
               })

      payload =
        Path.join(output_dir, "stage_evidence_labels.json")
        |> File.read!()
        |> Jason.decode!()

      assert payload["stage_evidence_labels"]["stage3_method_evolution"] == "evidence_backed"
      assert payload["stage_evidence_labels"]["stage4_institution_adaptation"] == "evidence_backed"
      assert payload["stage_evidence_labels"]["stage5_civilization_adaptation"] == "simulated"

      assert payload["stage_provenance"]["stage4_institution_adaptation"] ==
               "genuine_engine_over_stage3_method_evolution_outputs"
    end

    test "stage4 evidence_backed without stage3 evidence_backed raises", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:s4_guard)

      assert_raise ArgumentError, ~r/requires\s+stage_modes\.stage3_method_evolution/, fn ->
        RecursiveCivilizationRunner.execute(1, %{
          authorized: true,
          output_dir: output_dir,
          episodes_per_generation: 3,
          institutions: [inst],
          stage_modes: %{stage4_institution_adaptation: :evidence_backed}
        })
      end
    end

    test "genuine evidence-backed stage4 defers proposals (never fabricates adoptions)", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:s4_defer)

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 5,
                 institutions: [inst],
                 stage_modes: %{
                   stage3_method_evolution: :evidence_backed,
                   stage4_institution_adaptation: :evidence_backed
                 }
               })

      payload =
        Path.join(output_dir, "stage4_evidence/generation_1.json")
        |> File.read!()
        |> Jason.decode!()

      # Evidence-backed mode never adopts — every compatible proposal defers
      assert payload["total_adopted"] == 0
      assert payload["total_deferred"] >= 0
    end

    test "attestation rows carry stage4 flipped label and provenance", %{output_dir: output_dir} do
      inst = unique_institution(:s4_attest)

      assert {:ok, _} =
               RecursiveCivilizationRunner.execute(1, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 3,
                 institutions: [inst],
                 stage_modes: %{
                   stage3_method_evolution: :evidence_backed,
                   stage4_institution_adaptation: :evidence_backed
                 }
               })

      [attestation] =
        Path.join(output_dir, "constitution_attestations.jsonl")
        |> File.read!()
        |> String.split("\n", trim: true)
        |> Enum.map(&Jason.decode!/1)

      assert attestation["stage_evidence_labels"]["stage4_institution_adaptation"] == "evidence_backed"

      assert attestation["stage_provenance"]["stage4_institution_adaptation"] ==
               "genuine_engine_over_stage3_method_evolution_outputs"
    end

    test "multi-generation genuine stage4 runs persist evidence each generation", %{
      output_dir: output_dir
    } do
      inst = unique_institution(:s4_multi)

      assert {:ok, histories} =
               RecursiveCivilizationRunner.execute(2, %{
                 authorized: true,
                 output_dir: output_dir,
                 episodes_per_generation: 4,
                 institutions: [inst],
                 stage_modes: %{
                   stage3_method_evolution: :evidence_backed,
                   stage4_institution_adaptation: :evidence_backed
                 }
               })

      assert length(histories) == 2
      assert File.exists?(Path.join(output_dir, "stage4_evidence/generation_1.json"))
      assert File.exists?(Path.join(output_dir, "stage4_evidence/generation_2.json"))
    end
  end
end
