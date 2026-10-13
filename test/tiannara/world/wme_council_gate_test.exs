defmodule Tiannara.World.WmeCouncilGateTest do
  @moduledoc """
  Gate-matrix unit evidence for the S07 migration: WorldMutationEngine under
  the wrapped-council-decision contract (Step-5 §8 row S07 — M2 wrap, G2-G4
  wrap verification, G4-machine condition-evidence check, M4 consumption,
  M8 audit edge, fail-closed branches).
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, Authorization, MachineAuthorization}
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}
  alias Tiannara.World.WorldMutationEngine

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  defp mut_spec(tag \\ "gate") do
    %{id: "#{tag}_#{System.unique_integer([:monotonic])}", type: :knowledge}
  end

  defp history_count do
    length(WorldMutationEngine.history(limit: 10_000))
  end

  defp record_for(spec_id) do
    WorldMutationEngine.history(limit: 10_000)
    |> Enum.find(fn record -> Map.get(record, :spec, %{})[:id] == spec_id end)
  end

  defp latest_audit_for(mutation_id) do
    AuditLog.recent(100)
    |> Enum.find(fn entry ->
      entry.action == :world_mutation_executed and
        is_map(entry.payload) and
        Map.get(entry.payload, :mutation_id) == mutation_id
    end)
  end

  describe "G4-machine condition-evidence check (G-9 fix)" do
    test "clean conditional decision meets conditions" do
      auth = %Authorization{
        decision: :conditional,
        evidence: [%{principle: :evidence_based, verdict: :neutral}],
        violated_principles: [],
        constitutional_score: 0.7,
        required_human_review: false
      }

      assert WorldMutationEngine.conditions_met?(auth)
    end

    test "conditional with unresolved violated principles fails conditions" do
      auth = %Authorization{
        decision: :conditional,
        evidence: [%{principle: :coherence, verdict: :violated}],
        violated_principles: [:coherence],
        constitutional_score: 0.688,
        required_human_review: false
      }

      refute WorldMutationEngine.conditions_met?(auth)
    end

    test "conditional without evidence fails conditions" do
      auth = %Authorization{
        decision: :conditional,
        evidence: [],
        violated_principles: [],
        constitutional_score: 0.7,
        required_human_review: false
      }

      refute WorldMutationEngine.conditions_met?(auth)
    end

    test "conditional below the score floor fails conditions" do
      auth = %Authorization{
        decision: :conditional,
        evidence: [%{principle: :safety, verdict: :neutral}],
        violated_principles: [],
        constitutional_score: 0.5,
        required_human_review: false
      }

      refute WorldMutationEngine.conditions_met?(auth)
    end

    test "conditional requiring human review fails conditions" do
      auth = %Authorization{
        decision: :conditional,
        evidence: [%{principle: :safety, verdict: :neutral}],
        violated_principles: [],
        constitutional_score: 0.7,
        required_human_review: true
      }

      refute WorldMutationEngine.conditions_met?(auth)
    end

    test "unknown mutation type is refused through the real council path" do
      assert {:error, {:conditional_conditions_unmet, detail}} =
               WorldMutationEngine.mutate(:definitely_not_a_known_mutation_type, mut_spec("unknown"))

      assert is_map(detail)
      assert :coherence in detail.violated_principles
    end
  end

  describe "effect descriptor (M1)" do
    test "identity is deterministic and derived from the descriptor only" do
      spec = mut_spec("desc")

      first = WorldMutationEngine.effect_descriptor(:create_entity, spec)
      second = WorldMutationEngine.effect_descriptor(:create_entity, spec)

      assert {:ok, effect_id} = EffectIdentity.effect_id(first)
      assert {:ok, ^effect_id} = EffectIdentity.effect_id(second)
    end

    test "atom identity values are normalized to canonically representable strings" do
      descriptor = WorldMutationEngine.effect_descriptor(:create_entity, %{id: "x1", type: :knowledge})
      assert descriptor.target == %{id: "x1", type: "knowledge"}
      assert {:ok, _effect_id} = EffectIdentity.effect_id(descriptor)
    end

    test "operation and non-identity fields separate otherwise-equal specs" do
      %{id: id} = mut_spec("sep")

      create = WorldMutationEngine.effect_descriptor(:create_entity, %{id: id, type: :knowledge})
      refute = WorldMutationEngine.effect_descriptor(:refute_entity, %{id: id, type: :knowledge})

      assert {:ok, create_id} = EffectIdentity.effect_id(create)
      assert {:ok, refute_id} = EffectIdentity.effect_id(refute)
      refute create_id == refute_id
    end

    test "relationship identity covers from, to and type" do
      base = %{from_id: "a", to_id: "b", type: :related_to}
      other = %{from_id: "a", to_id: "c", type: :related_to}

      assert {:ok, id_a} = EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_relationship, base))
      assert {:ok, id_b} = EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_relationship, other))
      refute id_a == id_b
    end

    test "non-identity spec fields are excluded from the descriptor target" do
      descriptor =
        WorldMutationEngine.effect_descriptor(:create_entity, %{
          id: "only-this-matters",
          type: :knowledge,
          attributes: %{huge: "map"},
          confidence: 0.9
        })

      refute Map.has_key?(descriptor.target, :attributes)
      refute Map.has_key?(descriptor.target, :confidence)
      assert descriptor.target == %{id: "only-this-matters", type: "knowledge"}
    end
  end

  describe "M2 wrap on execution" do
    test "executed mutation records the wrap, effect identity and registry consumption" do
      spec = mut_spec("wrap")
      assert {:ok, mutation_id} = WorldMutationEngine.mutate(:create_entity, spec)

      record = record_for(spec.id)
      assert record.effect_id
      assert record.authorization_id
      assert record.machine_authorization

      wrap = struct(MachineAuthorization, record.machine_authorization)
      assert wrap.authorization_id == record.authorization_id
      assert wrap.authority_class == :machine
      assert wrap.decision_type == :world_mutation

      {:ok, expected} =
        EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_entity, spec))

      assert record.effect_id == expected
      assert wrap.effect_id == expected

      assert MintRegistry.status(wrap.authorization_id) == :consumed
      assert MintRegistry.binding(wrap.authorization_id) == {:ok, expected}

      assert entry = latest_audit_for(mutation_id)
      assert entry.payload.effect_id == expected
      assert entry.payload.authorization_id == wrap.authorization_id
      assert entry.payload.sink == :world_mutation_engine
    end

    test "each execution mints a distinct authorization id (no id reuse across calls)" do
      spec_a = mut_spec("distinct-a")
      spec_b = mut_spec("distinct-b")

      assert {:ok, _} = WorldMutationEngine.mutate(:create_entity, spec_a)
      assert {:ok, _} = WorldMutationEngine.mutate(:create_entity, spec_b)

      wrap_a = struct(MachineAuthorization, record_for(spec_a.id).machine_authorization)
      wrap_b = struct(MachineAuthorization, record_for(spec_b.id).machine_authorization)

      refute wrap_a.authorization_id == wrap_b.authorization_id
      refute wrap_a.effect_id == wrap_b.effect_id
    end
  end

  describe "fail-closed branches" do
    test "registry unavailable -> :authorization_registry_unavailable with no record" do
      pid = Process.whereis(MintRegistry)
      before_count = history_count()
      spec = mut_spec("reg-down")
      Process.unregister(MintRegistry)

      result =
        try do
          WorldMutationEngine.mutate(:create_entity, spec)
        after
          Process.register(pid, MintRegistry)
        end

      assert result == {:error, :authorization_registry_unavailable}
      assert history_count() == before_count
      refute record_for(spec.id)
    end

    test "audit unavailable fails the claim after the record and burns the wrap (N7)" do
      pid = Process.whereis(AuditLog)
      before_count = history_count()
      spec = mut_spec("audit-down")
      Process.unregister(AuditLog)

      result =
        try do
          WorldMutationEngine.mutate(:create_entity, spec)
        after
          Process.register(pid, AuditLog)
        end

      assert {:error, {:audit_not_recorded, _reason, detail}} = result
      assert detail.mutation_recorded == true
      assert detail.mutation_id
      assert history_count() == before_count + 1

      record = record_for(spec.id)
      assert record
      wrap = struct(MachineAuthorization, record.machine_authorization)
      assert MintRegistry.status(wrap.authorization_id) == :consumed
    end

    test "council emergency refuses every mutation with :constitutional_rejection" do
      :ok = Council.invoke_emergency(:wme_gate_test, "gate suite probe")

      try do
        assert {:error, {:constitutional_rejection, explanation}} =
                 WorldMutationEngine.mutate(:create_entity, mut_spec("emergency"))

        assert explanation =~ "emergency"
      after
        :ok = Council.lift_emergency(:wme_gate_test)
      end

      assert {:ok, _} = WorldMutationEngine.mutate(:create_entity, mut_spec("post-lift"))
    end

    test "decision types outside the permitted set fail closed" do
      assert {:error, {:decision_not_permitted, :deferred}} =
               WorldMutationEngine.check_decision(%Authorization{decision: :deferred})
    end
  end
end
