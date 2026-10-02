defmodule Tiannara.Sentinel.DiscoveryEnhancement do
  @moduledoc """
  Controlled lifecycle for corrections proposed by independent domains.

  A proposed correction never edits the original discovery. It becomes a
  candidate variant with explicit provenance, then must be re-tested and
  independently re-verified before it can supersede or improve the discovery.
  """

  @spec propose(map(), map(), map()) :: {:ok, map()} | {:error, term()}
  def propose(discovery, domain_result, correction)
      when is_map(discovery) and is_map(domain_result) and is_map(correction) do
    with :ok <- validate_correction(correction),
         :ok <- require_independent_domain(domain_result) do
      {:ok, %{
        enhancement_id: "enhancement-#{System.unique_integer([:positive])}",
        discovery_id: Map.get(discovery, :id),
        source_domain: Map.get(domain_result, :domain, Map.get(domain_result, :verification_domain)),
        correction: correction,
        parent_discovery: discovery,
        status: :proposed,
        execution_mode: :not_executed,
        evidence_class: :simulated,
        certification_eligible: false,
        acl_oavl_required: true,
        revalidation_required: true
      }}
    end
  end

  @spec record_test(map(), map()) :: {:ok, map()} | {:error, term()}
  def record_test(enhancement, test_result)
      when is_map(enhancement) and is_map(test_result) do
    if Map.get(enhancement, :status) == :proposed do
      {:ok, Map.merge(enhancement, %{
        status: :tested,
        test_result: test_result,
        tested_at: DateTime.utc_now(),
        certification_eligible: false
      })}
    else
      {:error, :enhancement_not_proposed}
    end
  end

  defp validate_correction(correction) do
    if Map.has_key?(correction, :problem) and Map.has_key?(correction, :proposed_change) and
         Map.has_key?(correction, :expected_effect),
      do: :ok,
      else: {:error, :incomplete_domain_correction}
  end

  defp require_independent_domain(result) do
    if Map.get(result, :independent, false) == true and is_atom(Map.get(result, :status)),
      do: :ok,
      else: {:error, :correction_source_not_independently_verified}
  end
end
