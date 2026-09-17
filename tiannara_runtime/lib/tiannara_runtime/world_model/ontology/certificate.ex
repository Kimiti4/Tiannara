defmodule TiannaraRuntime.WorldModel.Ontology.CertificationCheck do
  @moduledoc """
  Phase 17 — CertificationCheck: a single check within a model certificate.
  """
  @enforce_keys [:check_name, :status]
  defstruct [:check_name, :status, :description, :evidence]

  @type check_status :: :pass | :fail | :skipped

  @type t :: %__MODULE__{
          check_name: String.t(),
          status: check_status(),
          description: String.t(),
          evidence: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    cc = %__MODULE__{
      check_name: Keyword.get(opts, :check_name),
      status: Keyword.get(opts, :status),
      description: Keyword.get(opts, :description, ""),
      evidence: Keyword.get(opts, :evidence)
    }
    validate(cc)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{check_name: cn}) when is_nil(cn) or cn == "",
    do: {:error, "CertificationCheck check_name must not be empty"}
  def validate(%__MODULE__{status: s}) when s not in ~w(pass fail skipped)a,
    do: {:error, "CertificationCheck status must be one of: pass, fail, skipped"}
  def validate(%__MODULE__{} = cc), do: {:ok, cc}
  def validate(_), do: {:error, "invalid CertificationCheck"}
end

defmodule TiannaraRuntime.WorldModel.Ontology.ModelCertificate do
  @moduledoc """
  Phase 17 — ModelCertificate: constitutional certification of a world model.
  """
  @enforce_keys [:certificate_id, :model_id, :model_version, :certification_type]
  defstruct [
    :certificate_id,
    :model_id,
    :model_version,
    :certification_type,
    :checks,
    :overall_status,
    :fingerprint,
    :issued_at,
    :issued_by,
    :supersedes
  ]

  @type cert_type :: :mathematical | :validation | :operational
  @type cert_status :: :pass | :fail | :pending
  @type issuer :: :self | :auditor

  @type t :: %__MODULE__{
          certificate_id: String.t(),
          model_id: String.t(),
          model_version: non_neg_integer(),
          certification_type: cert_type(),
          checks: [TiannaraRuntime.WorldModel.Ontology.CertificationCheck.t()],
          overall_status: cert_status(),
          fingerprint: String.t() | nil,
          issued_at: String.t(),
          issued_by: issuer(),
          supersedes: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    mc = %__MODULE__{
      certificate_id: Keyword.get(opts, :certificate_id, generate_id()),
      model_id: Keyword.get(opts, :model_id),
      model_version: Keyword.get(opts, :model_version, 1),
      certification_type: Keyword.get(opts, :certification_type),
      checks: Keyword.get(opts, :checks, []),
      overall_status: Keyword.get(opts, :overall_status, :pending),
      fingerprint: Keyword.get(opts, :fingerprint),
      issued_at: Keyword.get(opts, :issued_at, now),
      issued_by: Keyword.get(opts, :issued_by, :self),
      supersedes: Keyword.get(opts, :supersedes)
    }
    validate(mc)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{model_id: mid}) when is_nil(mid) or mid == "",
    do: {:error, "ModelCertificate model_id must not be empty"}
  def validate(%__MODULE__{certification_type: ct}) when ct not in ~w(mathematical validation operational)a,
    do: {:error, "ModelCertificate certification_type must be one of: mathematical, validation, operational"}
  def validate(%__MODULE__{checks: cs}) when not is_list(cs),
    do: {:error, "ModelCertificate checks must be a list"}
  def validate(%__MODULE__{issued_by: ib}) when ib not in ~w(self auditor)a,
    do: {:error, "ModelCertificate issued_by must be one of: self, auditor"}
  def validate(%__MODULE__{} = mc), do: {:ok, mc}
  def validate(_), do: {:error, "invalid ModelCertificate"}

  defp generate_id, do: "cert_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
end

defmodule TiannaraRuntime.WorldModel.Ontology.ValidationEvidence do
  @moduledoc """
  Phase 17 — ValidationEvidence: metric results from model validation against evidence.
  """
  @enforce_keys [:validation_id, :model_id, :model_version, :metric, :value, :threshold]
  defstruct [
    :validation_id,
    :model_id,
    :model_version,
    :metric,
    :value,
    :threshold,
    :passed,
    :evidence_fingerprint,
    :created_at
  ]

  @type metric :: :rmse | :log_likelihood | :coverage | :calibration | :custom

  @type t :: %__MODULE__{
          validation_id: String.t(),
          model_id: String.t(),
          model_version: non_neg_integer(),
          metric: metric(),
          value: float(),
          threshold: float(),
          passed: boolean(),
          evidence_fingerprint: String.t() | nil,
          created_at: String.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    value = Keyword.get(opts, :value, 0.0)
    threshold = Keyword.get(opts, :threshold, 0.0)

    ve = %__MODULE__{
      validation_id: Keyword.get(opts, :validation_id, generate_id()),
      model_id: Keyword.get(opts, :model_id),
      model_version: Keyword.get(opts, :model_version, 1),
      metric: Keyword.get(opts, :metric),
      value: value,
      threshold: threshold,
      passed: Keyword.get(opts, :passed, value <= threshold),
      evidence_fingerprint: Keyword.get(opts, :evidence_fingerprint),
      created_at: Keyword.get(opts, :created_at, now)
    }
    validate(ve)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{model_id: mid}) when is_nil(mid) or mid == "",
    do: {:error, "ValidationEvidence model_id must not be empty"}
  def validate(%__MODULE__{metric: m}) when m not in ~w(rmse log_likelihood coverage calibration custom)a,
    do: {:error, "ValidationEvidence metric must be one of: rmse, log_likelihood, coverage, calibration, custom"}
  def validate(%__MODULE__{} = ve), do: {:ok, ve}
  def validate(_), do: {:error, "invalid ValidationEvidence"}

  defp generate_id, do: "val_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
end
