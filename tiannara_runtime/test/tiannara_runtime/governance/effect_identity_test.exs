defmodule TiannaraRuntime.Governance.EffectIdentityTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Governance.EffectIdentity

  @base %{
    effect_schema_version: "effect-v1",
    principal: "human:amos",
    authority: %{id: "omega-deployer", scope: "production"},
    authorization_scope: %{resource_scope: "candidate", operation_scope: ["deploy"], parameter_constraints: %{}},
    operation: "deploy",
    target: %{namespace: "omega", resource_type: "candidate", resource_id: "cand-001", subresource: nil},
    parameters: %{mode: "supervised", replicas: 1},
    intent: "deploy candidate",
    environment_scope: %{type: "production", id: "prod-ke-1", region: "ke-central"},
    authority_epoch: "epoch-7",
    policy_version: "policy-42"
  }

  test "deterministic bytes and EffectID" do
    assert {:ok, bytes1} = EffectIdentity.canonical_bytes(@base)
    assert {:ok, bytes2} = EffectIdentity.canonical_bytes(%{@base | parameters: %{replicas: 1, mode: "supervised"}})
    assert bytes1 == bytes2
    assert {:ok, id} = EffectIdentity.effect_id(@base)
    assert id == "a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50"
  end

  for {field, value} <- [
        {:principal, "human:other"},
        {:operation, "delete"},
        {:intent, "delete candidate"},
        {:authority_epoch, "epoch-8"},
        {:policy_version, "policy-43"}
      ] do
    test "semantic field #{field} changes EffectID" do
      changed = Map.put(@base, unquote(field), unquote(value))
      assert {:ok, base_id} = EffectIdentity.effect_id(@base)
      assert {:ok, changed_id} = EffectIdentity.effect_id(changed)
      refute base_id == changed_id
    end
  end

  test "lifecycle metadata is excluded" do
    noisy = Map.merge(@base, %{request_id: "req-999", correlation_id: "corr-999", execution_id: "exec-999", deployment_id: "deploy-999", mutation_id: "mut-999", attempt: 7, worker_id: "worker-3"})
    assert EffectIdentity.effect_id(@base) == EffectIdentity.effect_id(noisy)
  end

  test "unsupported BEAM values hard fail" do
    assert {:error, {:unsupported_value, :parameters}} = EffectIdentity.effect_id(%{@base | parameters: self()})
  end

  test "schema mismatch hard fails" do
    assert {:error, {:unsupported_schema_version, "effect-v2"}} = EffectIdentity.effect_id(%{@base | effect_schema_version: "effect-v2"})
  end

  test "missing semantic field hard fails" do
    assert {:error, {:missing_fields, _}} = EffectIdentity.effect_id(Map.delete(@base, :intent))
  end

  test "forged EffectID is rejected" do
    assert {:error, {:effect_id_mismatch, _}} = EffectIdentity.verify(@base, String.duplicate("0", 64))
  end
end
