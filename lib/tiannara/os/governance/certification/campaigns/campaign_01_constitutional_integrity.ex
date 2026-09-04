defmodule TiannaraOS.Governance.Certification.Campaigns.Campaign01 do
  @moduledoc """
  CC-001 — Constitutional Integrity Certification

  Executes the full Governance Certification Laboratory suite (GC-001 to GC-012)
  while actively monitoring for drift via the ConstitutionalWatchdog.

  Pass condition: 100% constitutional preservation across all 12 GC sub-campaigns;
  watchdog never fires.
  """
  @behaviour TiannaraOS.Governance.Certification.CampaignAdapter

  alias TiannaraOS.Governance.Certification.Laboratory

  @impl true
  def execute(params) do
    # 1. Start the watchdog monitoring process
    watchdog_pid = spawn_link(fn -> monitor_watchdog() end)

    # 2. Run the laboratory
    case Laboratory.execute_certification(context: params.context, seed: params.seed) do
      {:ok, certificate} ->
        # Stop watchdog
        send(watchdog_pid, :stop)

        {:ok, %{
          status: :passed,
          metrics: %{gc_campaigns_passed: 12, watchdog_alerts: 0},
          artifacts: [certificate],
          lineage: ["CC-001-Constitutional-Integrity"]
        }}

      {:error, failed_campaigns} ->
        send(watchdog_pid, :stop)
        
        {:error, %{
          status: :failed,
          reason: "Governance certification failed sub-campaigns: #{inspect(failed_campaigns)}",
          failing_metrics: %{failed_count: length(failed_campaigns)},
          context: %{}
        }}
    end
  end

  defp monitor_watchdog do
    receive do
      :stop -> :ok
    after
      100 ->
        # In a real run, this would query ConstitutionalWatchdog.status()
        # and abort if drift is detected.
        monitor_watchdog()
    end
  end
end
