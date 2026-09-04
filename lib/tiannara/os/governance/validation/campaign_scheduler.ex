defmodule TiannaraOS.Governance.Validation.CampaignScheduler do
  @moduledoc """
  CampaignScheduler - Manages parallel/serial execution of campaign phases.

  This module takes an execution plan and schedules campaigns for execution,
  respecting phase boundaries and dependency constraints.

  Responsibilities:
  - Execute campaigns within a phase (potentially in parallel)
  - Wait for phase completion before proceeding to next phase
  - Handle retries and timeouts
  - Track execution progress
  """

  alias TiannaraOS.Governance.Validation.{
    CampaignExecutor,
    EvidenceCollector,
    EvidenceSigner
  }

  @type execution_plan :: map()
  @type adapter_map :: %{atom() => module()}
  @type evidence_artifact :: map()

  @doc """
  Execute entire campaign plan across all phases.

  Returns list of signed evidence artifacts from all campaigns.
  """
  @spec execute_plan(execution_plan(), adapter_map()) :: {:ok, [evidence_artifact()]} | {:error, term()}
  def execute_plan(%{phases: phases}, adapters) do
    results = execute_phases(phases, adapters, [])

    case Enum.all?(results, fn {_, result} -> match?({:ok, _}, result) end) do
      true ->
        {:ok, extract_evidence(results)}
      false ->
        {:error, :phase_failures_detected}
    end
  end

  # Execute phases sequentially
  defp execute_phases([], _adapters, acc), do: Enum.reverse(acc)

  defp execute_phases([phase | remaining], adapters, acc) do
    phase_results = execute_phase(phase, adapters)
    execute_phases(remaining, adapters, [{phase, phase_results} | acc])
  end

  # Execute all campaigns within a phase
  defp execute_phase(campaign_ids, adapters) do
    campaign_ids
    |> Task.async_stream(fn campaign_id ->
      spec = load_campaign_spec(campaign_id)
      execute_single_campaign(spec, adapters)
    end, max_concurrency: length(campaign_ids))
    |> Enum.map(fn {:ok, result} -> result end)
  end

  # Execute single campaign through full pipeline
  defp execute_single_campaign(spec, adapters) do
    start_time = System.system_time(:millisecond)

    with {:ok, execution_data} <- CampaignExecutor.execute_campaign(spec, adapters),
         unsigned_artifact <- EvidenceCollector.collect_evidence(spec, execution_data, start_time),
         signed_artifact <- EvidenceSigner.sign_artifact(unsigned_artifact) do
      {:ok, signed_artifact}
    else
      {:error, reason} ->
        {:error, %{campaign_id: spec.campaign_id, reason: reason}}
    end
  end

  # Load campaign spec from registry
  defp load_campaign_spec(campaign_id) do
    {:ok, spec} = TiannaraOS.Governance.Validation.CampaignRegistry.get_campaign(campaign_id)
    spec
  end

  # Extract evidence artifacts from phase results
  defp extract_evidence(phase_results) do
    phase_results
    |> List.flatten()
    |> Enum.filter(fn
      {:ok, _artifact} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, artifact} -> artifact end)
  end
end
