defmodule ObservatoryApi.Controllers.CertificationController do
  use ObservatoryApi, :controller

  alias TiannaraOS.Provenance.CertificateIssuance

  def status(conn, _params) do
    certificates = safe_certificates()

    json(conn, %{
      success: true,
      data: %{
        status: if(certificates == [], do: "unverified", else: "verified"),
        certificates: certificates
      },
      api_version: Shared.Constants.api_version()
    })
  end

  def chain(conn, _params) do
    json(conn, %{
      success: true,
      data: %{chain: safe_certificates()},
      api_version: Shared.Constants.api_version()
    })
  end

  defp safe_certificates do
    CertificateIssuance.export()
    |> Enum.filter(&(&1["state"] == "VALID"))
    |> Enum.map(fn record ->
      Map.take(record, [
        "certificate_id",
        "state",
        "decision",
        "issuance_spec",
        "recorded_at"
      ])
    end)
  rescue
    _ -> []
  end
end
