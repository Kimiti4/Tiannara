defmodule TiannaraRuntime.Mathematics.CounterexampleEngine do
  @moduledoc """
  Counterexample search boundary.

  The engine never declares a universal statement true. It requires an actual
  search backend and reports falsifying examples or an explicit search limit.
  """

  @spec search(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def search(statement, opts \ []) when is_map(statement) do
    backend = Keyword.get(opts, :backend)

    cond do
      not is_function(backend, 1) ->
        {:error, :counterexample_search_backend_unavailable}

      true ->
        case backend.(statement) do
          {:counterexample, example} ->
            {:ok, %{status: :falsified, counterexample: example,
                    evidence_class: :mathematical_test, certification_eligible: false}}
          :none_found ->
            {:ok, %{status: :not_falsified, search_exhausted: false,
                    evidence_class: :mathematical_test, certification_eligible: false}}
          {:exhausted, details} ->
            {:ok, %{status: :inconclusive, search_exhausted: true, details: details,
                    evidence_class: :mathematical_test, certification_eligible: false}}
          {:error, reason} ->
            {:error, reason}
          other ->
            {:error, {:invalid_counterexample_backend_result, other}}
        end
    end
  end
end
