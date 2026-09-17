defmodule TiannaraRuntime.WorldModel.Composition.CompositionCertificate do
  @moduledoc """
  Phase 17.6.1 — CompositionCertificate struct.
  Certifies a composed world model after all checks pass.
  Fields: certificate_id, composition_id, checks, overall, issued_by, issued_at, metadata.
  """
  defstruct [:certificate_id, :composition_id, :checks, :overall, :issued_by, :issued_at, :metadata]

  @type overall :: :pass | :fail
  @type t :: %__MODULE__{
          certificate_id: String.t() | nil,
          composition_id: String.t() | nil,
          checks: [map()] | nil,
          overall: overall() | nil,
          issued_by: atom() | nil,
          issued_at: String.t() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "cc_" <> hash
  end
end
