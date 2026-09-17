defmodule TiannaraRuntime.WorldModel.Behaviours.CertificateIssuer do
  @moduledoc """
  Phase 17 — CertificateIssuer behaviour.

  Defines the contract for certifying world models at each tier of the
  certification framework. Implementations must provide deterministic,
  replayable certification that produces verifiable certificates.

  ## Tiers
    - :mathematical — equation parseability, dimensional consistency, solvability
    - :validation — predictive accuracy, calibration, cross-validation
    - :operational — full chain: replay determinism, evidence lineage, constitutional compliance
  """

  @doc "Issue a certificate for a model at the given tier."
  @callback certify(model :: map(), tier :: atom()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()}
              | {:error, String.t()}

  @doc "Issue certificates for all tiers (mathematical -> validation -> operational)."
  @callback certify_all_tiers(model :: map()) ::
              {:ok, [TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()]}
              | {:error, String.t()}

  @doc "Re-issue a certificate for a model at the given tier (e.g. after evidence refresh)."
  @callback re_certify(model_id :: String.t(), tier :: atom()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()}
              | {:error, String.t()}

  @doc "Revoke a previously issued certificate."
  @callback revoke(certificate_id :: String.t(), reason :: String.t()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()}
              | {:error, String.t()}

  @doc "Verify that a certificate is internally consistent and matches its model."
  @callback verify(certificate :: TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()) ::
              :pass
              | {:fail, String.t()}
end
