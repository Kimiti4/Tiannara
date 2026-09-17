defmodule TiannaraRuntime.Mathematics.Validation.Validator do
  @moduledoc """
  Phase 16.X.95 — Constitutional Mathematics Validation Campaign Orchestrator

  Runs all 10 validation campaigns, accepts campaign filters, tracks
  aggregate metrics, and returns a consolidated validation result.
  """

  @campaigns [
    :contract, :replay, :serialization, :proof, :conjecture,
    :verification, :runtime, :stress, :failure_injection, :archaeology
  ]

  defstruct results: %{}, metrics: %{}, status: :not_run

  @doc """
  Run all or filtered validation campaigns.

  Options:
    - `:campaigns` — list of campaign atoms to run (default: all 10)
    - `:timeout` — per-campaign timeout in milliseconds (default: 30_000)
    - `:report` — whether to generate reports after running (default: false)
  """
  @spec run(keyword()) :: %__MODULE__{}
  def run(opts \\ []) do
    selected = Keyword.get(opts, :campaigns, @campaigns)
    timeout = Keyword.get(opts, :timeout, 30_000)
    generate_report? = Keyword.get(opts, :report, false)

    {results, metrics} =
      selected
      |> Enum.reduce({%{}, %{}}, fn campaign, {res_acc, met_acc} ->
        campaign_opts = Keyword.put(opts, :timeout, timeout)

        case run_campaign(campaign, campaign_opts) do
          {:ok, result} ->
            campaign_metrics = Map.get(result, :metrics, %{})
            {
              Map.put(res_acc, campaign, result),
              merge_metrics(met_acc, campaign_metrics, campaign)
            }

          {:error, reason} ->
            failed = %{status: :error, error: reason, campaign: campaign}
            {
              Map.put(res_acc, campaign, failed),
              Map.put(met_acc, campaign, %{status: :error, error: reason})
            }
        end
      end)

    status = compute_status(results)

    validation = %__MODULE__{results: results, metrics: metrics, status: status}

    if generate_report? do
      generate_reports(validation)
    end

    validation
  end

  @doc """
  Dispatch to an individual campaign module.

  The campaign module must implement the `TiannaraRuntime.Mathematics.Validation.Campaign`
  behaviour and be named `TiannaraRuntime.Mathematics.Validation.<CampaignName>`.
  """
  @spec run_campaign(atom(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def run_campaign(campaign, opts) do
    module = campaign_module(campaign)

    if Code.ensure_loaded?(module) && function_exported?(module, :run, 1) do
      try do
        module.run(opts)
      rescue
        e ->
          {:ok, %{
            campaign: campaign,
            status: :error,
            checks: [%{check: "campaign_crash", status: :error, detail: "#{inspect(e)}"}],
            summary: %{total: 0, passed: 0, failed: 0, errors: 1}
          }}
      catch
        kind, value ->
          {:ok, %{
            campaign: campaign,
            status: :error,
            checks: [%{check: "campaign_crash", status: :error, detail: "#{kind}: #{inspect(value)}"}],
            summary: %{total: 0, passed: 0, failed: 0, errors: 1}
          }}
      end
    else
      {:error, "Campaign module #{inspect(module)} not found or does not implement run/1"}
    end
  end

  @doc """
  Generate all 11 deliverable reports from a validation result.

  Reports are written to `priv/validation_reports/`.
  """
  @spec generate_reports(%__MODULE__{}) :: :ok
  def generate_reports(validation_result) do
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_validation_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_contract_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_replay_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_serialization_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_proof_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_conjecture_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_verification_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_runtime_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_stress_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_failure_injection_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_archaeology_report(validation_result)
    TiannaraRuntime.Mathematics.Validation.ReportGenerator.generate_summary_json(validation_result)
    :ok
  end

  @doc """
  Show a human-readable summary of the validation run.
  """
  @spec summary(%__MODULE__{}) :: String.t()
  def summary(validation) do
    total = map_size(validation.results)
    passed =
      validation.results
      |> Enum.count(fn {_name, r} -> Map.get(r, :status, :error) == :pass end)
    failed =
      validation.results
      |> Enum.count(fn {_name, r} -> Map.get(r, :status, :error) == :fail end)
    errors =
      validation.results
      |> Enum.count(fn {_name, r} -> Map.get(r, :status, :error) == :error end)

    lines = [
      "╔══════════════════════════════════════════════╗",
      "║  Phase 16.X.95 — Validation Summary          ║",
      "╠══════════════════════════════════════════════╣",
      "║  Total campaigns : #{String.pad_leading("#{total}", 21)} ║",
      "║  Passed          : #{String.pad_leading("#{passed}", 21)} ║",
      "║  Failed          : #{String.pad_leading("#{failed}", 21)} ║",
      "║  Errors          : #{String.pad_leading("#{errors}", 21)} ║",
      "║  Overall status  : #{String.pad_leading("#{validation.status}", 18)} ║",
      "╚══════════════════════════════════════════════╝"
    ]

    Enum.join(lines, "\n")
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp campaign_module(:contract), do: TiannaraRuntime.Mathematics.Validation.ContractValidation
  defp campaign_module(:replay), do: TiannaraRuntime.Mathematics.Validation.DeterministicReplay
  defp campaign_module(:serialization), do: TiannaraRuntime.Mathematics.Validation.SerializationValidation
  defp campaign_module(:proof), do: TiannaraRuntime.Mathematics.Validation.ProofValidation
  defp campaign_module(:conjecture), do: TiannaraRuntime.Mathematics.Validation.ConjectureValidation
  defp campaign_module(:verification), do: TiannaraRuntime.Mathematics.Validation.FormalVerification
  defp campaign_module(:runtime), do: TiannaraRuntime.Mathematics.Validation.RuntimeValidation
  defp campaign_module(:stress), do: TiannaraRuntime.Mathematics.Validation.StressValidation
  defp campaign_module(:failure_injection), do: TiannaraRuntime.Mathematics.Validation.FailureInjection
  defp campaign_module(:archaeology), do: TiannaraRuntime.Mathematics.Validation.ArchaeologyValidation

  defp merge_metrics(acc, new_metrics, campaign) do
    Map.put(acc, campaign, new_metrics)
  end

  defp compute_status(results) when map_size(results) == 0, do: :not_run

  defp compute_status(results) do
    any_error = Enum.any?(results, fn {_k, r} -> Map.get(r, :status, :pass) == :error end)
    any_fail = Enum.any?(results, fn {_k, r} -> Map.get(r, :status, :pass) == :fail end)

    cond do
      any_error -> :error
      any_fail -> :fail
      true -> :pass
    end
  end
end
