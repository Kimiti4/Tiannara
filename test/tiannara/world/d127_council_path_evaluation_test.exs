defmodule Tiannara.World.D127CouncilPathEvaluationTest do
  @moduledoc """
  D127 evaluation protocol (Step-5 §6) executed against the fourth and final
  minimum path: the machine-class (council) path — `WorldMutationEngine.mutate/3`
  under the wrapped-council-decision contract (Step-5 §8 row S07).

  Constructive attacks are presented through the path's real boundaries: the
  consumed M2 wrap at the mint registry, the caller-controlled inputs at the
  mutate API, and the stored wrap/record observable via history/0. Each property
  expects a named refusal or a verified invariant; D127's disposition after this
  suite is recorded by the Step-10 artifact, never inferred from this file.
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

  defp mut_spec(tag) do
    %{id: "d127c_#{tag}_#{System.unique_integer([:monotonic])}", type: :knowledge}
  end

  defp record_for(spec_id) do
    WorldMutationEngine.history(limit: 10_000)
    |> Enum.find(fn record -> Map.get(record, :spec, %{})[:id] == spec_id end)
  end

  defp wrap_for(spec_id) do
    spec_id
    |> record_for()
    |> Map.fetch!(:machine_authorization)
    |> then(&struct(MachineAuthorization, &1))
  end

  defp execute(tag, opts \\ []) do
    spec = Keyword.get(opts, :spec) || mut_spec(tag)
    context = Keyword.get(opts, :context)
    assert {:ok, mutation_id} = WorldMutationEngine.mutate(:create_entity, spec, context)
    {spec, mutation_id, wrap_for(spec.id)}
  end

  defp audit_edge(mutation_id) do
    AuditLog.recent(200)
    |> Enum.find(fn entry ->
      entry.action == :world_mutation_executed and
        is_map(entry.payload) and
        Map.get(entry.payload, :mutation_id) == mutation_id
    end)
  end

  describe "D127 protocol rows — machine-class (council) path (S07)" do
    test "D127.1 replay: consumed wrap re-presented to the registry -> :already_consumed" do
      {_spec, _mid, wrap} = execute("r1")

      assert MintRegistry.status(wrap.authorization_id) == :consumed
      assert MintRegistry.consume(wrap.authorization_id, wrap.effect_id) ==
               {:error, :already_consumed}

      {_spec_b, _mid_b, wrap_b} = execute("r1b")
      refute wrap.authorization_id == wrap_b.authorization_id
    end

    test "D127.2 copy: one wrap presented four times -> zero copies execute, singular status" do
      {_spec, _mid, wrap} = execute("c1")

      results =
        for _ <- 1..4 do
          MintRegistry.consume(wrap.authorization_id, wrap.effect_id)
        end

      assert Enum.all?(results, &(&1 == {:error, :already_consumed}))
      assert MintRegistry.status(wrap.authorization_id) == :consumed
      assert MintRegistry.binding(wrap.authorization_id) == {:ok, wrap.effect_id}
    end

    test "D127.3 delegation: emergency lockdown refuses forged-elevation inputs; caller context cannot widen authority" do
      :ok = Council.invoke_emergency(:d127_council_path, "D127.3 delegation probe")

      try do
        forged = %{actor: :council_overlord, authority: :root, bypasses_human_authority: false}

        assert {:error, {:constitutional_rejection, explanation}} =
                 WorldMutationEngine.mutate(:create_entity, mut_spec("d3"), forged)

        assert explanation =~ "emergency"
      after
        :ok = Council.lift_emergency(:d127_council_path)
      end

      {_spec_a, _mid_a, wrap_clean} = execute("d3clean")

      forged_context = %{actor: :human_overlord, authority: :root, claims: [:admin]}
      {_spec_b, _mid_b, wrap_forged} = execute("d3forged", context: forged_context)

      assert wrap_clean.authority_class == :machine
      assert wrap_forged.authority_class == :machine
      assert wrap_forged.authority_ref == wrap_clean.authority_ref
      assert wrap_forged.decision.policy_applied == wrap_clean.decision.policy_applied
      assert wrap_forged.decision.policy_applied == :rule_engine
      assert wrap_forged.decision_type == wrap_clean.decision_type
    end

    test "D127.4 amplification: decided, bound, recorded and audited effect identity is equal; context cannot smuggle a broader spec; tampering breaks the seal" do
      spec = mut_spec("a1")

      smuggled = %{mutation_spec: %{id: "d127c_smuggled_elsewhere"}}

      assert {:ok, mutation_id} =
               WorldMutationEngine.mutate(:create_entity, spec, smuggled)

      record = record_for(spec.id)
      assert record.spec == spec

      {:ok, expected} =
        EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_entity, spec))

      wrap = struct(MachineAuthorization, record.machine_authorization)
      assert record.effect_id == expected
      assert wrap.effect_id == expected

      assert entry = audit_edge(mutation_id)
      assert entry.payload.effect_id == expected
      assert entry.payload.authorization_id == wrap.authorization_id
      assert entry.payload.operation == "create_entity"

      tampered = %MachineAuthorization{wrap | ttl: 999_999}
      refute MachineAuthorization.content_hash(tampered) == tampered.content_hash
      assert MachineAuthorization.content_hash(wrap) == wrap.content_hash
    end

    test "D127.5 other-effect: wrap bound to effect A refused against effect B -> :registry_binding_mismatch" do
      spec_a = mut_spec("e1")
      spec_b = mut_spec("e2")

      {:ok, effect_a} =
        EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_entity, spec_a))

      {:ok, effect_b} =
        EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_entity, spec_b))

      refute effect_a == effect_b

      decision =
        Council.authorize(
          :world_mutation,
          %{
            mutation_type: :create_entity,
            mutation_spec: spec_a,
            context: nil,
            evidence: [%{source: :d127_council_path}],
            actor: :d127_council_path,
            coherent_with_mission: true,
            degradation_handled: true
          },
          nil
        )

      {:ok, fresh} = MachineAuthorization.mint(decision, decision_type: :world_mutation)

      {:ok, bound_a} =
        MachineAuthorization.bind_effect(
          fresh,
          WorldMutationEngine.effect_descriptor(:create_entity, spec_a)
        )

      assert bound_a.effect_id == effect_a
      assert MintRegistry.binding(bound_a.authorization_id) == {:ok, effect_a}

      assert MintRegistry.consume(bound_a.authorization_id, effect_b) ==
               {:error, :registry_binding_mismatch}

      assert MintRegistry.status(bound_a.authorization_id) == :granted
    end

    test "D127.6 reconstruction: forged wrap never registered -> :not_registered; injected decision struct has no consumer; foreign mutation type refused" do
      {_spec, _mid, wrap} = execute("f1")

      forged_id = :"mauth-reconstructed-#{System.unique_integer([:monotonic])}"
      forged = %MachineAuthorization{wrap | authorization_id: forged_id}

      assert MintRegistry.status(forged.authorization_id) == :not_registered
      assert MintRegistry.consume(forged.authorization_id, forged.effect_id) ==
               {:error, :not_registered}

      injected = %Authorization{decision: :approved, policy_applied: :forged_council}
      {_spec_b, _mid_b, wrap_b} = execute("f2", context: %{authorization: injected})

      assert wrap_b.decision.policy_applied == :rule_engine
      refute wrap_b.decision.policy_applied == :forged_council
      refute wrap_b.authority_ref == :forged_council

      assert {:error, {:conditional_conditions_unmet, detail}} =
               WorldMutationEngine.mutate(:constitutional_amendment, mut_spec("f3"))

      assert :coherence in detail.violated_principles
    end
  end

  describe "fail-closed extras" do
    test "registry unavailable -> :authorization_registry_unavailable with no record and no audit edge" do
      before_count = length(WorldMutationEngine.history(limit: 10_000))
      pid = Process.whereis(MintRegistry)
      spec = mut_spec("x1")
      Process.unregister(MintRegistry)

      result =
        try do
          WorldMutationEngine.mutate(:create_entity, spec)
        after
          Process.register(pid, MintRegistry)
        end

      assert result == {:error, :authorization_registry_unavailable}
      assert length(WorldMutationEngine.history(limit: 10_000)) == before_count
      refute record_for(spec.id)
    end

    test "audit unavailable fails the claim after the record and burns the wrap (N7)" do
      pid = Process.whereis(AuditLog)
      spec = mut_spec("x2")
      Process.unregister(AuditLog)

      result =
        try do
          WorldMutationEngine.mutate(:create_entity, spec)
        after
          Process.register(pid, AuditLog)
        end

      assert {:error, {:audit_not_recorded, _reason, detail}} = result
      assert detail.mutation_recorded == true

      record = record_for(spec.id)
      assert record
      wrap = struct(MachineAuthorization, record.machine_authorization)
      assert MintRegistry.status(wrap.authorization_id) == :consumed
    end
  end

  describe "negative control" do
    test "legitimate council-path mutation executes with identity equality and a verified audit edge" do
      {spec, mutation_id, wrap} = execute("ctrl")

      {:ok, expected} =
        EffectIdentity.effect_id(WorldMutationEngine.effect_descriptor(:create_entity, spec))

      assert wrap.effect_id == expected
      assert MintRegistry.status(wrap.authorization_id) == :consumed
      assert MintRegistry.binding(wrap.authorization_id) == {:ok, expected}

      record = record_for(spec.id)
      assert record.effect_id == expected
      assert record.authorization_id == wrap.authorization_id
      assert record.status == :executed

      assert entry = audit_edge(mutation_id)
      assert entry.payload.effect_id == expected
      assert entry.payload.authorization_id == wrap.authorization_id
      assert entry.payload.sink == :world_mutation_engine
      assert :ok = AuditLog.verify_integrity
    end
  end
end
