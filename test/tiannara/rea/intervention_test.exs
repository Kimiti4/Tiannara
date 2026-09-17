defmodule Tiannara.REA.InterventionTest do
  use ExUnit.Case, async: false

  alias Tiannara.REA.Intervention

  setup do
    original_exists = File.exists?("data/interventions.ndjson")
    original_content = if original_exists, do: File.read!("data/interventions.ndjson"), else: nil

    on_exit(fn ->
      if original_exists do
        File.write!("data/interventions.ndjson", original_content)
      else
        File.rm_rf!("data/interventions.ndjson")
      end
    end)

    :ok
  end

  test "intervention state persistence" do
    File.rm_rf!("data/interventions.ndjson")

    interventions = Intervention.all()
    assert length(interventions) == 2

    new_int = %Intervention{
      id: "test_int",
      origin_discovery_id: "structured_forgetting",
      origin_law_id: "structured_forgetting",
      origin_theory_id: "test_theory",
      proposal_text: "Set retention to 40%",
      confidence: 0.88,
      expected_effect: "None",
      actual_effect: nil,
      status: :proposed
    }

    {:ok, saved} = Intervention.save(new_int)
    assert saved.id == "test_int"

    reloaded = Intervention.all()
    assert length(reloaded) == 3
    test_entry = Enum.find(reloaded, & &1.id == "test_int")
    assert test_entry.proposal_text == "Set retention to 40%"
    assert test_entry.status == :proposed
  end
end
