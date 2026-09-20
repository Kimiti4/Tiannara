defmodule Tiannara.Certification.ExerciseRunnerRemediationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Certification.ExerciseRunner

  test "missing independent executor is UNKNOWN, never PASS" do
    result = ExerciseRunner.run_exercise("1.1", :default, fn _ ->
      %{passed: true, confidence: 1.0, metrics: %{}}
    end)

    assert result.status == :unknown
    assert result.evidence_class == :not_verified
    refute result.passed
    assert result.confidence == 0.0
  end

  test "external executor is the only execution path" do
    executor = fn "x", :prompt, 1000 -> {:ok, %{observed: true}} end

    result =
      ExerciseRunner.run_exercise(
        "x",
        :prompt,
        fn output -> %{passed: output.observed, confidence: 0.0, metrics: %{}} end,
        executor: executor,
        timeout: 1000
      )

    assert result.status == :success
    assert result.evidence_class == :runtime
    assert result.passed
  end
end
