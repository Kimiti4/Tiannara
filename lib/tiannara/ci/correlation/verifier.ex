defmodule Tiannara.CI.Correlation.Verifier do
  @moduledoc """
  Enforces the correlation invariant: a CI result must never be attributed to
  an improvement proposal unless its correlation identity is proven.

  Rejects:
    * unknown correlation_ids (never dispatched)
    * correlation_ids that belong to a different proposal (mismatch)

  Constitutional basis: Verification First, Security by design, "Maintain
  audit trails."
  """

  alias Tiannara.CI.Correlation.{Registry, Token}

  @doc """
  Verify a correlation_id is known (was dispatched). Returns
  `{:ok, record}` or `{:error, reason}`.
  """
  def verify_correlation(correlation_id, path) do
    cond do
      not Token.valid?(correlation_id) ->
        {:error, :invalid_correlation_token}

      true ->
        case Registry.lookup(correlation_id, path) do
          {:ok, record} -> {:ok, record}
          :not_found -> {:error, :unknown_correlation_id}
        end
    end
  end

  @doc """
  Verify a correlation_id belongs to a specific proposal. Rejects mismatches.
  This is the check that prevents attributing one proposal's CI result to
  another proposal.
  """
  def verify_matches(correlation_id, expected_proposal_id, path) do
    case verify_correlation(correlation_id, path) do
      {:ok, %{proposal_id: ^expected_proposal_id} = record} ->
        {:ok, record}

      {:ok, %{proposal_id: other}} ->
        {:error, {:correlation_mismatch, expected: expected_proposal_id, got: other}}

      {:error, _} = e ->
        e
    end
  end
end