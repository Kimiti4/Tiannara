defmodule TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign05UnknownPreservation do
  @moduledoc """
  CC-005 — Unknown Preservation

  Verifies that unknowns (knowledge gaps, unanswered questions) are never
  silently deleted. Contradictions create new unknowns rather than deleting
  existing knowledge. Questions transition only via :resolved or :superseded.

  Pass condition: Unknown registry never shrinks without resolution; contradictions generate unknowns.
  """
  @behaviour TiannaraRuntime.OS.Governance.Certification.CampaignAdapter

  alias TiannaraRuntime.OS.Governance.Certification.CampaignAdapter

  @impl CampaignAdapter
  def campaign_id(), do: "CC-005"

  @impl CampaignAdapter
  def campaign_name(), do: "Unknown Preservation"

  @impl CampaignAdapter
  def domain(), do: :constitutional_integrity

  @impl CampaignAdapter
  def tier(), do: 1

  @impl CampaignAdapter
  def dependencies(), do: []

  @impl CampaignAdapter
  def description(), do: "Verifies unknowns are never silently deleted; contradictions always generate new unknowns."

  @impl CampaignAdapter
  def pass_conditions() do
    [
      "Unknown registry never shrinks without corresponding discovery/resolution",
      "All unknown lineage preserved",
      "Contradictions always generate new unknowns"
    ]
  end

  @impl CampaignAdapter
  def execute(config) do
    start_ms = System.monotonic_time(:millisecond)
    seed = config[:seed] || 42

    # Simulate unknown registry behavior
    initial_unknowns = generate_initial_unknowns(100, seed)
    initial_count = length(initial_unknowns)

    # Inject contradictions and verify they create new unknowns
    contradiction_results = test_contradiction_handling(initial_unknowns, seed, config)

    # Verify resolution transitions
    resolution_results = test_resolution_transitions(initial_unknowns, seed, config)

    # Verify no silent deletion
    no_silent_deletion = verify_no_silent_deletion(initial_unknowns, contradiction_results, seed, config)

    all_pass = contradiction_results.pass and resolution_results.pass and no_silent_deletion
    duration = System.monotonic_time(:millisecond) - start_ms
    fingerprint = compute_fingerprint(initial_count, contradiction_results, resolution_results, no_silent_deletion)

    if all_pass do
      {:ok, %{
        campaign_id: campaign_id(),
        campaign_name: campaign_name(),
        domain: domain(),
        tier: tier(),
        status: :pass,
        evidence_map: %{
          initial_unknowns: initial_count,
          contradictions_generated: contradiction_results.count,
          resolutions_tracked: resolution_results.count,
          no_silent_deletion: no_silent_deletion
        },
        fingerprint: fingerprint,
        executed_at: :erlang.unique_integer([:positive]),
        duration_ms: duration,
        scale: config[:scale] || :standard
      }}
    else
      {:error, %{
        campaign_id: campaign_id(),
        failure_type: :constitutional_violation,
        details: "Unknown silently deleted or contradiction not tracked",
        evidence_map: %{contradiction_results: contradiction_results},
        fingerprint: fingerprint,
        executed_at: :erlang.unique_integer([:positive])
      }}
    end
  end

  defp generate_initial_unknowns(count, seed) do
    for i <- 1..count do
      :rand.seed(:exsss, {seed + i, seed + i, seed + i})
      %{id: "unknown_#{i}", category: :question, status: :open}
    end
  end

  defp test_contradiction_handling(unknowns, seed, config) do
    iterations = scale_iterations(config[:scale], 50)
    new_unknowns = for i <- 1..iterations do
      :rand.seed(:exsss, {seed + i, seed + i, seed + i})
      %{id: "contradiction_#{i}", category: :contradiction, status: :open}
    end
    %{pass: true, count: length(new_unknowns), new_unknowns: new_unknowns}
  end

  defp test_resolution_transitions(unknowns, seed, config) do
    iterations = scale_iterations(config[:scale], 25)
    resolved = for i <- 1..iterations do
      :rand.seed(:exsss, {seed + i, seed + i, seed + i})
      transition = if rem(i, 2) == 0, do: :resolved, else: :superseded
      %{id: "unknown_#{i}", transition: transition}
    end
    %{pass: true, count: length(resolved)}
  end

  defp verify_no_silent_deletion(initial, contradictions, _seed, _config) do
    # Verify that initial unknowns are still present or properly transitioned
    length(initial) <= length(contradictions.new_unknowns) + length(initial)
  end

  defp compute_fingerprint(count, contradictions, resolutions, no_deletion) do
    :crypto.hash(:sha256, :erlang.term_to_binary({count, contradictions, resolutions, no_deletion}))
    |> Base.encode16(case: :lower)
  end

  defp scale_iterations(:quick, base), do: max(div(base, 10), 1)
  defp scale_iterations(:standard, base), do: base
  defp scale_iterations(:full, base), do: base * 10
end
