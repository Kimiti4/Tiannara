defmodule Tiannara.Omega.RL565RegistryPersistenceRecoveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{DecisionReceipt, MachineAuthorization}
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.World.UnifiedWorldModel
  import Tiannara.Test.RegistryFixtures

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    :ok
  end

  defp genuine(entity_id) do
    scope = %{operation: "delete_entity", target: %{entity_id: entity_id}, effect_id: nil}

    {:ok, decision, receipt} =
      Council.decide(
        :delete_entity,
        %{
          mutation_type: :delete_entity,
          mutation_spec: %{id: entity_id},
          target: scope.target,
          scope: scope,
          context: nil,
          evidence: [%{source: :recovery}],
          actor: :recovery,
          coherent_with_mission: true,
          degradation_handled: true
        },
        nil
      )

    {:ok, grant} =
      MachineAuthorization.mint(decision, receipt,
        decision_type: :delete_entity,
        scope: scope,
        ttl: 3600
      )

    {decision, receipt, grant, scope}
  end

  test "clean round-trip preserves receipt and grant state across reload" do
    entity_id = "recovery_rt_#{System.unique_integer([:positive])}"
    {decision, receipt, grant, _scope} = genuine(entity_id)

    assert MintRegistry.receipt_status(receipt.receipt_id) == :consumed
    assert MintRegistry.status(grant.authorization_id) == :granted

    assert :ok = MintRegistry.reload()

    assert MintRegistry.receipt_status(receipt.receipt_id) == :consumed
    assert MintRegistry.status(grant.authorization_id) == :granted
    assert MintRegistry.decision_ref(grant.authorization_id) == grant.council_decision_ref
  end

  test "truncated tail marks registry corrupt" do
    path = MintRegistry.path()
    snapshot = snapshot(path)

    try do
      truncate_tail(path, 5)
      assert {:error, :registry_corrupt} = MintRegistry.reload()
      assert MintRegistry.status(:"any") == :registry_corrupt
    after
      restore(path, snapshot)
      MintRegistry.reload()
    end
  end

  test "MAC tamper marks registry corrupt" do
    path = MintRegistry.path()
    snapshot = snapshot(path)

    try do
      content = File.read!(path)
      # flip a byte in the middle
      mid = div(byte_size(content), 2)
      <<prefix::binary-size(mid), b, rest::binary>> = content
      File.write!(path, <<prefix::binary, (Bitwise.bxor(b, 1))::8, rest::binary>>)
      assert {:error, :registry_corrupt} = MintRegistry.reload()
    after
      restore(path, snapshot)
      MintRegistry.reload()
    end
  end

  test "sequence gap marks registry corrupt" do
    path = MintRegistry.path()
    snapshot = snapshot(path)

    try do
      event1 = {:receipt_issue, %{receipt_id: "r1", receipt_digest: String.duplicate("0", 64), decision_digest: String.duplicate("1", 64), decision_type: :delete_entity, scope_digest: String.duplicate("2", 64), actor: :a, issuer: "tiannara.council/v1", policy_version: "p", constitution_version: "1.0.0", issued_at: DateTime.utc_now(), expires_at: DateTime.add(DateTime.utc_now(), 300, :second)}}
      event2 = {:receipt_issue, %{receipt_id: "r2", receipt_digest: String.duplicate("0", 64), decision_digest: String.duplicate("1", 64), decision_type: :delete_entity, scope_digest: String.duplicate("2", 64), actor: :a, issuer: "tiannara.council/v1", policy_version: "p", constitution_version: "1.0.0", issued_at: DateTime.utc_now(), expires_at: DateTime.add(DateTime.utc_now(), 300, :second)}}

      File.write!(path, encode_record(1, event1))
      File.write!(path, encode_record(3, event2), [:append])

      assert {:error, :registry_corrupt} = MintRegistry.reload()
    after
      restore(path, snapshot)
      MintRegistry.reload()
    end
  end

  test "consumed grant stays consumed after reload" do
    entity_id = "recovery_consume_#{System.unique_integer([:positive])}"
    {_decision, _receipt, grant, _scope} = genuine(entity_id)

    {:ok, bound} =
      MachineAuthorization.bind_effect(grant, UnifiedWorldModel.effect_descriptor(entity_id))

    assert :ok = MintRegistry.consume(bound.authorization_id, bound.effect_id)

    assert :ok = MintRegistry.reload()
    assert MintRegistry.status(grant.authorization_id) == :consumed
  end

  test "receipt replay refused after reload" do
    entity_id = "recovery_replay_#{System.unique_integer([:positive])}"
    {decision, receipt, _grant, scope} = genuine(entity_id)

    assert :ok = MintRegistry.reload()

    assert {:error, :council_decision_receipt_consumed} =
             MachineAuthorization.mint(decision, receipt,
               decision_type: :delete_entity,
               scope: scope,
               ttl: 3600
             )
  end
end
