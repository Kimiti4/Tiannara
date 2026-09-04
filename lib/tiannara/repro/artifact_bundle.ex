defmodule Tiannara.Repro.ArtifactBundle do
  @moduledoc """
  The immutable artifact bundle a single run produces.

      Run -> ArtifactBundle -> (comparison) -> Reproducibility verdict

  Contains the manifest (deterministic inputs), the results (outputs), and a
  pointer to the provenance ledger so the bundle is independently
  reconstructable and auditable.
  """

  @enforce_keys [:manifest, :results]
  defstruct [:manifest, :results, :provenance_ref, :produced_at]

  def new(manifest, results, provenance_ref \\ nil) do
    %__MODULE__{
      manifest: manifest,
      results: results,
      provenance_ref: provenance_ref,
      produced_at: DateTime.utc_now()
    }
  end
end
