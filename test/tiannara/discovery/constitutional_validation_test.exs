defmodule Tiannara.Discovery.ConstitutionalValidationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.ConstitutionalValidation, as: Validation

  test "SV-001 canonical serialization and content IDs are deterministic" do
    attrs_a = %{source: "sensor-a", values: [1, 2, 3], uncertainty: 0.01}
    attrs_b = %{uncertainty: 0.01, values: [1, 2, 3], source: "sensor-a"}
    assert {:ok, entity_a} = Validation.build_entity(:observation, attrs_a)
    assert {:ok, entity_b} = Validation.build_entity(:observation, attrs_b)
    assert entity_a.id == entity_b.id
    assert :ok = Validation.validate_entity(entity_a)
  end

  test "SV-002 registry ledger is append-only, owned and replayable" do
    assert {:ok, observation} = Validation.build_entity(:observation, %{value: 42})

    assert {:ok, hypothesis} =
             Validation.build_entity(:hypothesis, %{accept: "value > 40", reject: "value <= 40"})

    assert {:ok, ledger} = Validation.append([], observation, "researcher-1")
    assert {:ok, ledger} = Validation.append(ledger, hypothesis, "researcher-1")
    assert :ok = Validation.validate_ledger(ledger)
    assert {:ok, state_a} = Validation.replay(ledger)
    assert {:ok, state_b} = Validation.replay(ledger)
    assert state_a.state_root == state_b.state_root
    assert state_a.owners[observation.id] == "researcher-1"
  end

  test "RV-003 theory replay preserves lineage" do
    entities =
      for revision <- 1..100 do
        {:ok, entity} =
          Validation.build_entity(:theory, %{
            theory: "A",
            revision: revision,
            parent: revision - 1
          })

        entity
      end

    ledger =
      Enum.reduce(entities, [], fn entity, acc ->
        {:ok, next} = Validation.append(acc, entity, "theory-engine")
        next
      end)

    assert {:ok, first} = Validation.replay(ledger)
    assert {:ok, second} = Validation.replay(ledger)
    assert first.state_root == second.state_root
    assert map_size(first.entities) == 100
  end

  test "RV-004 graph replay ignores input ordering" do
    nodes = [%{id: "b", type: "theory"}, %{id: "a", type: "observation"}]
    edges = [%{id: "e2", source: "b", target: "a"}, %{id: "e1", source: "a", target: "b"}]

    assert Validation.graph_hash(nodes, edges) ==
             Validation.graph_hash(Enum.reverse(nodes), Enum.reverse(edges))
  end

  test "RV-005 capital deltas reconstruct identical balances" do
    deltas =
      for amount <- [5, -2, 7],
          do: elem(Validation.build_entity(:capital_delta, %{account: "r1", amount: amount}), 1)

    ledger =
      Enum.reduce(deltas, [], fn entity, acc ->
        {:ok, next} = Validation.append(acc, entity, "capital-engine")
        next
      end)

    assert {:ok, state} = Validation.replay(ledger)
    assert state.capital["r1"] == 10
  end

  test "Tier 4 rejects claims missing required statistics" do
    complete = %{
      sample_size: 100,
      variance: 1.2,
      effect_size: 0.4,
      confidence_interval: [0.2, 0.6],
      power: 0.99,
      significance: 0.01,
      uncertainty: 0.05
    }

    assert :ok = Validation.validate_statistical_claim(complete)

    assert {:error, {:missing_statistics, [:uncertainty]}} =
             Validation.validate_statistical_claim(Map.delete(complete, :uncertainty))
  end

  test "DR-001 and DR-006 detect evidence and replay mutation" do
    {:ok, evidence} = Validation.build_entity(:evidence, %{result: true})
    {:ok, ledger} = Validation.append([], evidence, "lab-1")
    corrupted = put_in(ledger, [Access.at(0), :entity, :attributes, :result], false)
    assert {:error, :content_id_mismatch} = Validation.validate_ledger(corrupted)
  end

  test "DR-002 detects theory lineage corruption" do
    {:ok, theory} = Validation.build_entity(:theory, %{parent: "root", confidence: 0.7})
    {:ok, ledger} = Validation.append([], theory, "theory-engine")
    corrupted = put_in(ledger, [Access.at(0), :entity, :attributes, :parent], "forged")
    assert {:error, :content_id_mismatch} = Validation.validate_ledger(corrupted)
  end

  test "DR-003 graph corruption changes the graph fingerprint" do
    nodes = [%{id: "n1", value: 1}]
    assert Validation.graph_hash(nodes, []) != Validation.graph_hash([%{id: "n1", value: 2}], [])
  end

  test "DR-004 duplicate evidence has the same content address" do
    {:ok, first} = Validation.build_entity(:evidence, %{sample: 7})
    {:ok, duplicate} = Validation.build_entity(:evidence, %{sample: 7})
    assert first.id == duplicate.id
    assert MapSet.size(MapSet.new([first.id, duplicate.id])) == 1
  end

  test "DR-005 forged certificate is rejected" do
    signed =
      Validation.sign_certificate(
        %{certificate_id: "cert-1", status: "PASS"},
        "authorized-test-key"
      )

    assert :ok = Validation.verify_certificate(signed, "authorized-test-key")

    assert {:error, :invalid_signature} =
             Validation.verify_certificate(%{signed | status: "FORGED"}, "authorized-test-key")

    assert {:error, :invalid_signature} = Validation.verify_certificate(signed, "wrong-key")
  end
end
