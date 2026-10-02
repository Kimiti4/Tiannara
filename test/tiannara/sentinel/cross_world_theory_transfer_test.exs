defmodule Tiannara.Sentinel.CrossWorldTheoryTransferTest do
  use ExUnit.Case, async: true
  alias Tiannara.Sentinel.CrossWorldTheoryTransfer

  test "transfers a failed theory as a quarantined candidate" do
    source = %{id: "e1", statement: "X causes Y", status: :refuted, assumptions: [:a]}
    assert {:ok, transfer} =
      CrossWorldTheoryTransfer.prepare(source, %{world_id: "w2", civilization_id: "c7"})
    assert transfer.transfer_mode == :quarantined_research_candidate
    assert transfer.source_truth_status == :unchanged
    assert transfer.target_truth_status == :unknown
  end

  test "records target-world outcomes without promoting the source theory" do
    source = %{id: "e1", statement: "X causes Y", status: :superseded}
    assert {:ok, transfer} = CrossWorldTheoryTransfer.prepare(source, %{world_id: "w2"})
    assert {:ok, result} = CrossWorldTheoryTransfer.record_result(transfer, %{
      scenario_id: "s1",
      outcome: :mixed,
      observations: [:x],
      counterevidence: [:y],
      assumptions_held: [:a],
      assumptions_changed: [:b]
    })
    assert result.source_evidence_id == "e1"
    assert result.target_world_id == "w2"
    assert result.certification_eligible == false
  end

  test "does not allow an accepted source theory through this failed-theory path" do
    assert {:error, :source_theory_not_transferable} =
      CrossWorldTheoryTransfer.prepare(
        %{id: "e1", statement: "X", status: :proven_under_assumptions},
        %{world_id: "w2"}
      )
  end
end
