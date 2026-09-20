defmodule ObservatoryApi.Controllers.StatusController do
  use ObservatoryApi, :controller

  alias TiannaraOS.Provenance.CertificateIssuance

  def health(conn, _params) do
    json(conn, %{
      status: "ok",
      timestamp: DateTime.utc_now(),
      version: Shared.Constants.api_version(),
      constitution: Shared.Constants.constitution_version()
    })
  end

  def status(conn, _params) do
    certificates = safe_certificates()

    json(conn, %{
      success: true,
      data: %{
        status: "operational",
        uptime: "N/A",
        apps: %{
          observatory_core: :running,
          telemetry_gateway: :running,
          event_store: :running,
          metrics_engine: :running,
          replay_store: :running,
          observatory_state: :running,
          rbac: :running
        }
      },
      certification: %{
        status: if(certificates == [], do: "unverified", else: "verified"),
        certificate_count: length(certificates)
      },
      api_version: Shared.Constants.api_version()
    })
  end

  def phase_omega(conn, _params) do
    report =
      try do
        Tiannara.PhaseOmega.Scanner.scan()
      rescue
        e -> %{error: "Phase Ω not available: #{inspect(e)}"}
      end

    json(conn, report)
  end

  def phase_omega_snapshot(conn, _params) do
    snapshot =
      try do
        Tiannara.PhaseOmega.SubsystemRegistry.snapshot()
      rescue
        _ -> %{error: "SubsystemRegistry not available"}
      end

    json(conn, snapshot)
  end

  defp safe_certificates do
    CertificateIssuance.export()
    |> Enum.map(fn record ->
      Map.take(record, ["certificate_id", "state", "decision"])
    end)
  rescue
    _ -> []
  end
end
