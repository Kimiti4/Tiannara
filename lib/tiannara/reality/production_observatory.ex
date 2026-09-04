defmodule Tiannara.Reality.ProductionObservatory do
  @moduledoc """
  Phase 21: The External Reality Sensor.
  Polls external production systems (Stripe, GitHub, Datadog) to verify that
  civilizational outputs generate actual real-world value.

  TRUTHFULNESS BOUNDARY: external telemetry is only trusted when it comes from
  a REAL, configured provider. Without an external provider configuration,
  `run_reconciliation_cycle/0` reports explicit unavailability and never feeds
  fabricated numbers into the RealityLedger.
  """
  require Logger

  @doc """
  Runs a reality reconciliation cycle.

  With no external provider configured (the default), reports
  `{:ok, %{status: :unavailable, reason: :no_external_provider}}` and does NOT
  write fabricatable revenue/error numbers into the RealityLedger.

  Provider contract (for a future real provider module):
    provider.fetch_github_merged_prs() :: non_neg_integer()
    provider.fetch_stripe_revenue()    :: non_neg_integer()
    provider.fetch_datadog_errors()    :: non_neg_integer()
  """
  def run_reconciliation_cycle do
    case observatory_provider() do
      nil ->
        Logger.info("🌍 [Observatory] No external provider configured — reality reconciliation UNAVAILABLE (no fabricated numbers fed).")
        {:ok, %{status: :unavailable, reason: :no_external_provider, fed_reality_ledger: false}}

      provider ->
        run_with_provider(provider)
    end
  end

  defp observatory_provider do
    if Application.get_env(:tiannara, :external_providers_enabled, false) == true do
      Application.get_env(:tiannara, :reality_observatory_provider)
    end
  end

  defp run_with_provider(provider) do
    merged_prs = provider.fetch_github_merged_prs()
    stripe_revenue = provider.fetch_stripe_revenue()
    prod_errors = provider.fetch_datadog_errors()

    Logger.info("   📡 [GitHub] #{merged_prs} merged PRs detected.")
    Logger.info("   💳 [Stripe] $#{stripe_revenue} in MRR detected.")
    Logger.info("   📉 [Datadog] #{prod_errors} production errors detected.")

    if stripe_revenue > 0 do
      Tiannara.Economics.RealityLedger.record_revenue("Stripe Production", stripe_revenue)
    end

    if prod_errors > 50 do
      Logger.error("🚨 [Observatory] Production error spike detected! Internal models are detached from reality.")
    end

    {:ok, %{status: :ok, source_provider: provider, fed_reality_ledger: stripe_revenue > 0}}
  rescue
    e ->
      Logger.error("[Observatory] Provider #{inspect(provider)} failed: #{inspect(e)}")
      {:error, {:provider_failed, e}}
  end
end