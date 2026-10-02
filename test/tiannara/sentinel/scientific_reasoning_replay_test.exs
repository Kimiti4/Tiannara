defmodule Tiannara.Sentinel.ScientificReasoningReplayTest do
  use ExUnit.Case, async: true
  alias Tiannara.Sentinel.ScientificReasoningReplay

  test "replays all consistent reasoning steps" do
    record = %{id: "r1", artifact: %{reasoning_steps: [%{claim: :a}, %{claim: :b}]}}
    observer = fn _step -> {:ok, :consistent} end

    assert {:ok, result} = ScientificReasoningReplay.replay(record, observer)
    assert result.steps_evaluated == 2
    assert result.first_divergence == nil
    assert result.lesson.type == :no_divergence_observed
  end

  test "localizes the first divergence and does not evaluate later steps" do
    send(self(), :start)
    record = %{id: "r2", artifact: %{reasoning_steps: [:observe, :hypothesize, :predict, :test]}}
    observer = fn
      %{value: :predict} -> {:error, :contradicted_by_observation}
      _ -> {:ok, :consistent}
    end

    assert {:ok, result} = ScientificReasoningReplay.replay(record, observer)
    assert result.first_divergence.index == 3
    assert result.first_divergence.outcome == :diverged
    assert result.lesson.action == :review_assumption_or_observation
    assert Enum.at(result.results, 3).outcome == :not_evaluated
  end

  test "rejects records without reasoning steps" do
    assert {:error, :reasoning_steps_unavailable} =
      ScientificReasoningReplay.replay(%{artifact: %{}}, fn _ -> {:ok, :ok} end)
  end
end
