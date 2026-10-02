defmodule Tiannara.Sentinel.TheoryValidationGate do
  @moduledoc """
  Mandatory ACL/OAVL boundary for theory evidence.

  ACL and OAVL are independent validation stages. This gate never substitutes
  a local heuristic for either stage. Missing providers therefore leave the
  theory unvalidated rather than allowing a simulation result to become truth.
  """

  @spec validate(map(), (map() -> {:ok, map()} | {:error, term()}) | nil,
        (map() -> {:ok, map()} | {:error, term()}) | nil) ::
          {:ok, map()} | {:error, term()}
  def validate(evidence, acl_validator, oavl_validator) when is_map(evidence) do
    with :ok <- require_validator(acl_validator, :acl),
         :ok <- require_validator(oavl_validator, :oavl),
         {:ok, acl} <- invoke(acl_validator, evidence, :acl),
         {:ok, oavl} <- invoke(oavl_validator, Map.put(evidence, :acl_result, acl), :oavl) do
      {:ok, %{
        acl_status: status(acl),
        oavl_status: status(oavl),
        acl_result: acl,
        oavl_result: oavl,
        validation_stage: :acl_oavl_complete,
        certification_eligible: false
      }}
    end
  end

  def validate(_, _, _), do: {:error, :invalid_theory_validation_input}

  defp require_validator(fun, name) when is_function(fun, 1), do: :ok
  defp require_validator(_, name), do: {:error, :"#{name}_validator_unavailable"}

  defp invoke(fun, evidence, name) do
    case fun.(evidence) do
      {:ok, result} when is_map(result) -> {:ok, result}
      {:error, reason} -> {:error, {:"#{name}_validation_failed", reason}}
      other -> {:error, {:"invalid_#{name}_validation_result", other}}
    end
  end

  defp status(result) do
    case Map.get(result, :status, Map.get(result, "status")) do
      value when value in [:pass, :passed] -> :passed
      value when value in [:fail, :failed] -> :failed
      _ -> :unknown
    end
  end
end
