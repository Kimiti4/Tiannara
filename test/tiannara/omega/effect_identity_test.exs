defmodule Tiannara.Omega.EffectIdentityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.EffectIdentity

  defp descriptor(overrides \\ %{}) do
    Map.merge(
      %{
        principal: "human:alice",
        authority_scope: "candidate:deploy",
        operation: "deploy",
        target: %{type: "candidate", id: "candidate-1"},
        parameters: %{mode: "production"},
        environment: %{region: "ke-1"},
        intent: "deploy the certified candidate",
        semantic_version: "1",
        identity_version: EffectIdentity.identity_version()
      },
      overrides
    )
  end

  test "same semantic descriptor has a stable effect identity" do
    assert {:ok, first} = EffectIdentity.effect_id(descriptor())
    assert {:ok, second} = EffectIdentity.effect_id(descriptor())

    assert first == second
  end

  test "map key ordering does not change identity" do
    a = descriptor(parameters: %{mode: "production", timeout: 30})
    b = descriptor(parameters: %{timeout: 30, mode: "production"})

    assert {:ok, id_a} = EffectIdentity.effect_id(a)
    assert {:ok, id_b} = EffectIdentity.effect_id(b)
    assert id_a == id_b
  end

  test "material semantic changes produce different identities" do
    assert {:ok, original} = EffectIdentity.effect_id(descriptor())

    assert {:ok, changed_operation} =
             EffectIdentity.effect_id(descriptor(operation: "delete"))

    assert {:ok, changed_target} =
             EffectIdentity.effect_id(
               descriptor(target: %{type: "candidate", id: "candidate-2"})
             )

    assert original != changed_operation
    assert original != changed_target
  end

  test "runtime metadata does not affect identity when excluded from semantics" do
    base = descriptor()
    retry = Map.put(base, :retry_count, 4)
    worker = Map.put(base, :worker_id, "worker-99")

    assert {:ok, original} = EffectIdentity.effect_id(base)
    assert {:ok, retry_id} = EffectIdentity.effect_id(retry)
    assert {:ok, worker_id} = EffectIdentity.effect_id(worker)

    assert original == retry_id
    assert original == worker_id
  end

  test "claimed identity is verified against canonical semantics" do
    assert {:ok, id} = EffectIdentity.effect_id(descriptor())
    assert :ok = EffectIdentity.verify(descriptor(), id)

    assert {:error, :effect_id_mismatch} =
             EffectIdentity.verify(descriptor(operation: "delete"), id)
  end

  test "missing semantic fields are rejected" do
    assert {:error, {:missing_fields, missing}} =
             EffectIdentity.effect_id(Map.delete(descriptor(), :target))

    assert "target" in missing
  end

  test "unsupported semantic values are rejected rather than guessed" do
    assert {:error, {:unsupported_value, self()}} =
             EffectIdentity.effect_id(descriptor(parameters: %{pid: self()}))
  end

  test "atom and string keys normalize to the same semantic representation" do
    string_descriptor =
      descriptor(%{
        "principal" => "human:alice",
        "authority_scope" => "candidate:deploy",
        "operation" => "deploy",
        "target" => %{"type" => "candidate", "id" => "candidate-1"},
        "parameters" => %{"mode" => "production"},
        "environment" => %{"region" => "ke-1"},
        "intent" => "deploy the certified candidate",
        "semantic_version" => "1",
        "identity_version" => EffectIdentity.identity_version()
      })

    atom_descriptor = descriptor()

    assert {:ok, string_id} = EffectIdentity.effect_id(string_descriptor)
    assert {:ok, atom_id} = EffectIdentity.effect_id(atom_descriptor)
    assert string_id == atom_id
  end
end
