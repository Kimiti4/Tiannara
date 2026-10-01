defmodule TiannaraRuntime.Mathematics.SearchOrchestratorTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.SearchOrchestrator

  test "search is bounded and never certification eligible" do
    candidates = [
      %{typing: %{type: :real, side_conditions: []}, expression: :a},
      %{typing: %{type: :real, side_conditions: []}, expression: :b},
      %{typing: %{type: :real, side_conditions: []}, expression: :c}
    ]

    {:ok, result} =
      SearchOrchestrator.search(
        candidates,
        [{:requires_type, :real}],
        fn candidate -> {:ok, %{candidate_id: candidate.expression}} end,
        budget: 2
      )

    assert result.budget == 2
    assert length(result.results) == 2
    assert result.certification_eligible == false
  end

  test "evaluator failure remains unavailable" do
    candidate = %{typing: %{type: :real, side_conditions: []}, expression: :x}

    {:ok, result} =
      SearchOrchestrator.search([candidate], [], fn _ -> {:error, :backend_unavailable} end)

    assert hd(result.results).search_status == :unavailable
    assert hd(result.results).evaluation.status == :unavailable
  end

  test "invalid search request fails" do
    assert {:error, :invalid_search_request} =
             SearchOrchestrator.search(:not_a_list, [], fn _ -> :ok end)
  end
end
