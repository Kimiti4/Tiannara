defmodule TiannaraRuntime.WorldModel.Pipeline.EvidenceIngestionTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry
  alias TiannaraRuntime.WorldModel.Pipeline.EvidenceIngestion
  alias TiannaraRuntime.WorldModel.Ontology.Evidence

  setup do
    ObservationRegistry.init_table()
    :ets.delete_all_objects(:observation_registry)
    :ok
  end

  defp register_experiment_observation(overrides \\ []) do
    origin = %{
      "source" => Keyword.get(overrides, :source, "particle_accelerator"),
      "domain" => Keyword.get(overrides, :domain, "physics"),
      "experiment_id" => Keyword.get(overrides, :experiment_id, "exp_001")
    }
    payload = Keyword.get(overrides, :payload, %{"value" => 42.0, "unit" => "GeV"})
    captured_at = Keyword.get(overrides, :captured_at, "2026-06-01T12:00:00Z")
    ObservationRegistry.register_observation(origin, payload, captured_at)
  end

  defp register_natural_observation(overrides \\ []) do
    origin = %{
      "source" => Keyword.get(overrides, :source, "telescope"),
      "domain" => Keyword.get(overrides, :domain, "astronomy")
    }
    payload = Keyword.get(overrides, :payload, %{"flux" => 3.5e-12, "band" => "xray"})
    captured_at = Keyword.get(overrides, :captured_at, "2026-06-01T13:00:00Z")
    ObservationRegistry.register_observation(origin, payload, captured_at)
  end

  defp register_simulation_observation(overrides \\ []) do
    origin = %{
      "source" => Keyword.get(overrides, :source, "nbody_sim"),
      "domain" => Keyword.get(overrides, :domain, "cosmology"),
      "simulation_id" => Keyword.get(overrides, :simulation_id, "sim_042")
    }
    payload = Keyword.get(overrides, :payload, %{"particles" => 1_000_000, "redshift" => 0.5})
    captured_at = Keyword.get(overrides, :captured_at, "2026-06-01T14:00:00Z")
    ObservationRegistry.register_observation(origin, payload, captured_at)
  end

  # --- ingest_evidence ---

  describe "ingest_evidence/1" do
    test "returns empty evidence when registry is empty" do
      {:ok, result} = EvidenceIngestion.ingest_evidence(domain: :physics)
      assert result.observation_count == 0
      assert result.classification == :unknown
      assert result.domain == :physics
      assert is_binary(result.evidence_id)
      assert is_binary(result.evidence_root)
    end

    test "fetches all observations when no domain filter" do
      register_experiment_observation()
      register_natural_observation()

      {:ok, result} = EvidenceIngestion.ingest_evidence()
      assert result.observation_count == 2
      assert result.classification == :mixed
    end

    test "filters by domain" do
      register_experiment_observation(domain: "physics")
      register_natural_observation(domain: "astronomy")

      {:ok, result} = EvidenceIngestion.ingest_evidence(domain: :physics)
      assert result.observation_count == 1
      assert result.domain == :physics
    end

    test "filters by time_window" do
      register_experiment_observation(captured_at: "2026-06-01T10:00:00Z")
      register_experiment_observation(captured_at: "2026-06-01T12:00:00Z")
      register_experiment_observation(captured_at: "2026-06-01T14:00:00Z")

      {:ok, result} = EvidenceIngestion.ingest_evidence(
        time_window: %{start: "2026-06-01T11:00:00Z", end: "2026-06-01T13:00:00Z"}
      )
      assert result.observation_count == 1
    end

    test "fetches by explicit observation_ids" do
      register_experiment_observation()
      register_natural_observation()
      register_simulation_observation()

      all = :ets.tab2list(:observation_registry)
      selected = Enum.take(all, 2) |> Enum.map(fn {id, _} -> id end)

      {:ok, result} = EvidenceIngestion.ingest_evidence(observation_ids: selected)
      assert result.observation_count == 2
    end
  end

  # --- classify_observations ---

  describe "classify_observations/1" do
    test "classifies controlled experiment" do
      obs = %{"origin" => %{"experiment_id" => "exp_001", "source" => "lab"}, "payload" => %{"x" => 1}}
      result = EvidenceIngestion.classify_observations([obs])
      assert result.classification == :controlled_experiment
      assert result.counts[:controlled_experiment] == 1
    end

    test "classifies natural observation" do
      obs = %{"origin" => %{"source" => "sensor"}, "payload" => %{"x" => 1}}
      result = EvidenceIngestion.classify_observations([obs])
      assert result.classification == :natural_observation
    end

    test "classifies simulation output" do
      obs = %{"origin" => %{"simulation_id" => "sim_001", "source" => "sim"}, "payload" => %{"x" => 1}}
      result = EvidenceIngestion.classify_observations([obs])
      assert result.classification == :simulation_output
    end

    test "mixed classification" do
      obs1 = %{"origin" => %{"experiment_id" => "e1"}, "payload" => %{"x" => 1}}
      obs2 = %{"origin" => %{"source" => "sensor"}, "payload" => %{"x" => 2}}
      result = EvidenceIngestion.classify_observations([obs1, obs2])
      assert result.classification == :mixed
    end

    test "empty returns unknown classification" do
      result = EvidenceIngestion.classify_observations([])
      assert result.classification == :unknown
    end

    test "classifies via metadata experiment_id" do
      obs = %{"origin" => %{"source" => "lab"}, "payload" => %{"x" => 1}, "metadata" => %{"experiment_id" => "exp_002"}}
      result = EvidenceIngestion.classify_observations([obs])
      assert result.classification == :controlled_experiment
    end

    test "classifies via metadata simulation_id" do
      obs = %{"origin" => %{"source" => "sim"}, "payload" => %{"x" => 1}, "metadata" => %{"simulation_id" => "sim_002"}}
      result = EvidenceIngestion.classify_observations([obs])
      assert result.classification == :simulation_output
    end
  end

  # --- fingerprinting ---

  describe "compute_observation_fingerprint/1" do
    test "returns deterministic fingerprint" do
      obs = %{"origin" => %{"source" => "test"}, "payload" => %{"x" => 1}}
      fp1 = EvidenceIngestion.compute_observation_fingerprint(obs)
      fp2 = EvidenceIngestion.compute_observation_fingerprint(obs)
      assert fp1 == fp2
      assert byte_size(fp1) == 64
    end

    test "is invariant to map key order" do
      obs1 = %{"origin" => %{"a" => 1, "b" => 2}, "payload" => %{"x" => 1}}
      obs2 = %{"payload" => %{"x" => 1}, "origin" => %{"b" => 2, "a" => 1}}
      assert EvidenceIngestion.compute_observation_fingerprint(obs1) ==
             EvidenceIngestion.compute_observation_fingerprint(obs2)
    end
  end

  describe "compute_evidence_root/1" do
    test "returns deterministic Merkle-style root" do
      obss = [
        %{"origin" => %{"source" => "a"}, "payload" => %{"x" => 1}},
        %{"origin" => %{"source" => "b"}, "payload" => %{"x" => 2}}
      ]
      r1 = EvidenceIngestion.compute_evidence_root(obss)
      r2 = EvidenceIngestion.compute_evidence_root(obss)
      assert r1 == r2
      assert byte_size(r1) == 64
    end

    test "is invariant to observation order" do
      obs_a = %{"origin" => %{"source" => "a"}, "payload" => %{"x" => 1}}
      obs_b = %{"origin" => %{"source" => "b"}, "payload" => %{"x" => 2}}
      r1 = EvidenceIngestion.compute_evidence_root([obs_a, obs_b])
      r2 = EvidenceIngestion.compute_evidence_root([obs_b, obs_a])
      assert r1 == r2
    end

    test "empty observations returns predictable root" do
      r = EvidenceIngestion.compute_evidence_root([])
      assert byte_size(r) == 64
    end

    test "root changes when observation content changes" do
      obs = %{"origin" => %{"source" => "a"}, "payload" => %{"x" => 1}}
      r1 = EvidenceIngestion.compute_evidence_root([obs])
      r2 = EvidenceIngestion.compute_evidence_root([%{obs | "payload" => %{"x" => 2}}])
      refute r1 == r2
    end
  end

  # --- Evidence struct ---

  describe "Evidence.new/1" do
    test "valid evidence with domain" do
      {:ok, ev} = Evidence.new(domain: :physics, observations: [], observation_count: 0)
      assert ev.domain == :physics
      assert ev.classification == :mixed
      assert is_binary(ev.evidence_id)
    end

    test "rejects nil domain" do
      assert {:error, _} = Evidence.new(domain: nil)
    end

    test "rejects invalid classification" do
      assert {:error, _} = Evidence.new(domain: :physics, classification: :bad_value)
    end

    test "rejects observation count mismatch" do
      assert {:error, _} = Evidence.new(domain: :physics, observations: [%{}], observation_count: 2)
    end
  end

  # --- fetch_observations ---

  describe "fetch_observations/3" do
    test "returns all observations without filters" do
      register_experiment_observation()
      register_natural_observation()
      {:ok, results} = EvidenceIngestion.fetch_observations(nil, nil, nil)
      assert length(results) == 2
    end
  end
end
