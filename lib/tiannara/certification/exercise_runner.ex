defmodule Tiannara.Certification.ExerciseRunner do
  @moduledoc """
  Certification exercise boundary.

  Certification exercises MUST execute through an explicitly supplied runtime
  executor. This module deliberately contains no certification-owned exercise
  implementations: if no runtime executor is supplied, the result is
  NOT_VERIFIED rather than PASS.

  This closes the previous self-contained exercise/evaluator loop.
  """

  @type result :: %{
          exercise_id: String.t(),
          status: :success | :error | :unknown,
          evidence_class: :runtime | :not_verified,
          passed: boolean(),
          confidence: float(),
          output: term(),
          duration_us: non_neg_integer(),
          metrics: map()
        }

  def run_exercise(exercise_id, prompt, evaluator_fn, opts \\ [])
      when is_binary(exercise_id) and is_function(evaluator_fn, 1) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    executor = Keyword.get(opts, :executor)

    case executor do
      executor when is_function(executor, 3) ->
        execute_external(executor, exercise_id, prompt, evaluator_fn, timeout)

      _ ->
        not_verified(exercise_id, "No independent runtime executor supplied")
    end
  end

  defp execute_external(executor, exercise_id, prompt, evaluator_fn, timeout) do
    start_us = System.monotonic_time(:microsecond)

    result =
      try do
        case executor.(exercise_id, prompt, timeout) do
          {:ok, output} -> {:ok, output}
          {:error, reason} -> {:error, reason}
          other -> {:ok, other}
        end
      rescue
        error -> {:error, Exception.message(error)}
      catch
        kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
      end

    duration_us = System.monotonic_time(:microsecond) - start_us

    case result do
      {:ok, output} ->
        evaluation = evaluator_fn.(output)

        %{
          exercise_id: exercise_id,
          status: :success,
          evidence_class: :runtime,
          output: output,
          duration_us: duration_us,
          passed: Map.get(evaluation, :passed, false),
          confidence: nil,
          confidence_basis: :not_derived_from_test_outcome,
          metrics: Map.get(evaluation, :metrics, %{})
        }

      {:error, reason} ->
        %{
          exercise_id: exercise_id,
          status: :error,
          evidence_class: :runtime,
          output: reason,
          duration_us: duration_us,
          passed: false,
          confidence: 0.0,
          metrics: %{error: reason}
        }
    end
  end

  defp not_verified(exercise_id, reason) do
    %{
      exercise_id: exercise_id,
      status: :unknown,
      evidence_class: :not_verified,
      output: nil,
      duration_us: 0,
      passed: false,
      confidence: 0.0,
      metrics: %{verification: :not_verified, reason: reason}
    }
  end
end
