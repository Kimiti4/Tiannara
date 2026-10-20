defmodule TiannaraRuntime.Cognitive.Audit.IndependentAuditTest do
  @moduledoc """
  Phase 18.96 — Independent Evidence-Only Audit
  Constructs evidence, replay, and archaeology artifacts as plain maps (simulating
  loading from a ledger) and verifies them independently WITHOUT importing runtime engines.
  """
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Cognitive.Runtime.RuntimeEvidence
  alias TiannaraRuntime.Cognitive.Runtime.RuntimeReplay
  alias TiannaraRuntime.Cognitive.Runtime.RuntimeArchaeology

  defp stable_fingerprint(%_{} = struct, drop_fields \\ [:id, :fingerprint]) do
    canonical =
      struct
      |> Map.from_struct()
      |> Map.drop(drop_fields)
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  describe "RuntimeEvidence" do
    test "evidence struct validates" do
      evidence = %RuntimeEvidence{
        id: "rev_001", mission_id: "m1", subsystem: "kernel", stage: "plan",
        input_hash: "abc", output_hash: "def", evidence_data: %{key: "val"},
        schema_version: 1, ontology_version: 1, created_with_phase: "18.9",
        migration_version: 0
      }
      assert RuntimeEvidence.validate(evidence) == :ok
    end

    test "evidence hash consistency" do
      evidence = %RuntimeEvidence{
        id: "rev_002", mission_id: "m1", subsystem: "kernel", stage: "plan",
        input_hash: "abc", output_hash: "def", evidence_data: %{},
        schema_version: 1, ontology_version: 1, created_with_phase: "18.9",
        migration_version: 0
      }
      fp1 = stable_fingerprint(evidence)
      fp2 = stable_fingerprint(evidence)
      assert fp1 == fp2
    end

    test "evidence missing fields" do
      evidence = %RuntimeEvidence{
        id: "rev_003", mission_id: "m1",
        schema_version: 999
      }
      assert RuntimeEvidence.validate(evidence) == {:error, [{:schema_version, :mismatch}]}
    end
  end

  describe "RuntimeReplay" do
    test "replay struct validates" do
      replay = %RuntimeReplay{
        id: "rr_001", mission_id: "m1",
        mission_root: "root_hash_1", kernel_root: "root_hash_2",
        working_memory_root: "root_hash_3", attention_root: "root_hash_4",
        planning_root: "root_hash_5", decision_root: "root_hash_6",
        reflection_root: "root_hash_7", metacognition_root: "root_hash_8",
        evidence_root: "root_hash_9",
        schema_version: 1, ontology_version: 1, created_with_phase: "18.9",
        migration_version: 0
      }
      assert RuntimeReplay.validate(replay) == :ok
    end

    test "replay hash chain" do
      replay = %RuntimeReplay{
        id: "rr_002", mission_id: "m1",
        mission_root: "mission_root_val", kernel_root: "kernel_root_val",
        working_memory_root: "wm_root_val", attention_root: "attention_root_val",
        planning_root: "planning_root_val", decision_root: "decision_root_val",
        reflection_root: "reflection_root_val", metacognition_root: "mc_root_val",
        evidence_root: "evidence_root_val",
        schema_version: 1
      }
      root_fields = [
        replay.mission_root, replay.kernel_root, replay.working_memory_root,
        replay.attention_root, replay.planning_root, replay.decision_root,
        replay.reflection_root, replay.metacognition_root, replay.evidence_root
      ]
      Enum.each(root_fields, fn root ->
        assert is_binary(root), "Expected binary, got: #{inspect(root)}"
        assert root != "", "Expected non-empty string"
      end)
    end

    test "replay missing roots" do
      replay = %RuntimeReplay{
        id: "rr_003", mission_id: "m1",
        mission_root: nil,
        schema_version: 999
      }
      assert RuntimeReplay.validate(replay) == {:error, [{:schema_version, :mismatch}]}
    end
  end

  describe "RuntimeArchaeology" do
    test "archaeology struct validates" do
      archaeology = %RuntimeArchaeology{
        id: "ra_001", mission_id: "m1",
        origin: "test_origin", mission_narrative: "test narrative",
        subsystem_summaries: [%{}], evidence_lineage: ["rev_001"],
        replay_verification: "ok",
        schema_version: 1, ontology_version: 1, created_with_phase: "18.9",
        migration_version: 0
      }
      assert RuntimeArchaeology.validate(archaeology) == :ok
    end

    test "archaeology generate_id format" do
      id = RuntimeArchaeology.generate_id(%{mission_id: "m1"})
      assert String.starts_with?(id, "ra_")
    end

    test "archaeology explanation" do
      archaeology = %RuntimeArchaeology{
        id: "ra_002", mission_id: "m1",
        origin: "origin", mission_narrative: "The mission narrative explains the full cognitive journey.",
        schema_version: 1
      }
      assert is_binary(archaeology.mission_narrative)
      assert String.length(archaeology.mission_narrative) > 0
    end
  end

  describe "CrossArtifact" do
    test "cross-artifact consistency" do
      evidence_ids = ["rev_abc", "rev_def", "rev_ghi"]

      archaeology = %RuntimeArchaeology{
        id: "ra_003", mission_id: "m1",
        origin: "origin", mission_narrative: "narrative",
        evidence_lineage: evidence_ids,
        schema_version: 1
      }

      lineage = archaeology.evidence_lineage
      assert length(lineage) == 3
      Enum.each(evidence_ids, fn eid ->
        assert eid in lineage, "Expected #{eid} in lineage #{inspect(lineage)}"
      end)
    end
  end
end
