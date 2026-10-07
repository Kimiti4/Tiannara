defmodule ObservatoryApi.Controllers.CertificationController do
  use ObservatoryApi, :controller

  @doc """
  Certification presentation is deliberately conservative.

  The Observatory must not manufacture a generic "certified" state. The
  authoritative provenance certificate lifecycle is a separate evidence-bound
  system; runtime certification is reported as inconclusive unless an actual
  certificate record is supplied.
  """
  def status(conn, _params) do
    json(conn, %{
      success: true,
      data: %{
        status: "not_verified",
        evidence_class: "no_authoritative_certificate_presented",
        certification_authority: "TiannaraOS.Provenance.CertificateIssuance"
      },
      api_version: Shared.Constants.api_version()
    })
  end

  def chain(conn, _params) do
    json(conn, %{
      success: true,
      data: %{
        chain: [],
        status: "not_verified",
        evidence_class: "no_authoritative_certificate_presented"
      },
      api_version: Shared.Constants.api_version()
    })
  end
end
