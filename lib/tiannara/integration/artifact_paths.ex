defmodule Tiannara.Integration.ArtifactPaths do
  @moduledoc """
  Paths to all artifacts used in soak reporting.
  """

  defstruct [
    :run_id,
    :funnel_events,
    :telemetry,
    :checkpoint_dir,
    :knowledge_dir,
    :recovery_attestation,
    :recovery_certificate,
    :constitutional_invariants,
    :output_dir
  ]

  def new(run_id, opts \\ []) do
    %__MODULE__{
      run_id: run_id,
      funnel_events: Keyword.get(opts, :funnel_events),
      telemetry: Keyword.get(opts, :telemetry),
      checkpoint_dir: Keyword.get(opts, :checkpoint_dir),
      knowledge_dir: Keyword.get(opts, :knowledge_dir),
      recovery_attestation: Keyword.get(opts, :recovery_attestation),
      recovery_certificate: Keyword.get(opts, :recovery_certificate),
      constitutional_invariants: Keyword.get(opts, :constitutional_invariants),
      output_dir: Keyword.get(opts, :output_dir)
    }
  end
end