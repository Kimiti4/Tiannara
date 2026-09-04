defmodule Tiannara.Repro.Manifest do
  @moduledoc """
  Formal experiment manifest for every long-duration test (Track F).

  Constitutional basis:
    * Safety & Reliability -- "Support reproducibility", "Maintain audit trails"
    * Evolution Framework -- "Preserve lineage"
    * Success Metrics     -- "Reproducibility"

  A manifest fully specifies the deterministic inputs of a run so Run B can
  be reconstructed from Run A's manifest and the two compared.
  """

  @enforce_keys [:experiment_id]
  defstruct [
    :experiment_id,
    :git_commit,
    :architecture_version,
    :constitution_version,
    :config_hash,
    :runtime_version,
    :elixir_version,
    :otp_version,
    :os,
    :hardware,
    :environment_variables,
    :dataset_identifiers,
    :seed,
    :randomness_config,
    :start_time,
    :end_time,
    :subsystem_versions,
     :checkpoint_lineage,
    :fault_injections,
    :recovery_verdict,
    :soak_time,
    :results,
    :verdict
  ]

  @type t :: %__MODULE__{}

  @doc """
  Captures the deterministic environment using real runtime introspection
  where available, plus caller-supplied values for system-specific fields
  (constitution version, datasets, checkpoint lineage, fault injections).
  """
  def capture(experiment_id, overrides \\ []) do
    env_vars = overrides |> Keyword.get(:environment_variables, []) |> Map.new()

    base = %__MODULE__{
      experiment_id: experiment_id,
      git_commit: detect_git_commit(),
      elixir_version: System.version(),
      otp_version: to_string(:erlang.system_info(:otp_release)),
      runtime_version: to_string(:erlang.system_info(:system_version)),
      os: detect_os(),
      hardware: detect_hardware(),
      environment_variables: env_vars,
      start_time: DateTime.utc_now()
    }

    Enum.reduce(overrides, base, fn {k, v}, acc ->
      if Map.has_key?(acc, k), do: Map.put(acc, k, v), else: acc
    end)
  end

  defp detect_git_commit do
    case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> :unknown
    end
  rescue
    _ -> :unknown
  end

  defp detect_os do
    {family, name} = :os.type()
    version = :os.version() |> Tuple.to_list() |> Enum.join(".")
    "#{family}/#{name} #{version}"
  end

  defp detect_hardware do
    %{
      logical_processors: :erlang.system_info(:logical_processors),
      wordsize: :erlang.system_info(:wordsize)
    }
  end

  @doc """
  Deterministic SHA-256 over the manifest's deterministic inputs only.
  Two manifests with the same config_hash describe the same experiment.

  Deliberately EXCLUDES non-deterministic fields: start_time, end_time,
  results, verdict.
  """
  def config_hash(manifest) do
    payload =
      %{
        git_commit: Map.get(manifest, :git_commit),
        architecture_version: Map.get(manifest, :architecture_version),
        constitution_version: Map.get(manifest, :constitution_version),
        environment_variables: Map.get(manifest, :environment_variables),
        dataset_identifiers: Map.get(manifest, :dataset_identifiers),
        seed: Map.get(manifest, :seed),
        randomness_config: Map.get(manifest, :randomness_config),
        subsystem_versions: Map.get(manifest, :subsystem_versions)
      }
      |> canonicalize()
      |> :erlang.term_to_binary()

    :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  end

  # Order-independent, deterministic term serialization.
  defp canonicalize(map) when is_map(map) and not is_struct(map) do
    map
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> {k, canonicalize(v)} end)
  end

  defp canonicalize(list) when is_list(list), do: Enum.map(list, &canonicalize/1)
  defp canonicalize(other), do: other

  @doc """
  Attaches a recovery attestation to the manifest.

    :gate_open        — recovery tests passed, soak is production-grade evidence
    :gate_closed      — recovery tests failed; evidence is unverified
    {:gate_closed, _} — recovery tests failed with missing checks

  Also stores soak timing for the attestation line.
  """
  def with_recovery(%__MODULE__{} = manifest, recovery_verdict, soak_time \\ nil) do
    %{manifest | recovery_verdict: recovery_verdict, soak_time: soak_time}
  end

  @doc """
  Human-readable attestation line for dashboard rendering.
  """
  def recovery_attestation(%__MODULE__{recovery_verdict: nil}) do
    "state: unattested   verdict: RECOVERY UNVERIFIED   (no recovery check performed)"
  end

  def recovery_attestation(%__MODULE__{recovery_verdict: :gate_open} = m) do
    time_str = format_soak_time(m.soak_time)
    "state: evidence_trusted   verdict: RECOVERY VERIFIED   #{time_str}"
  end

  def recovery_attestation(%__MODULE__{recovery_verdict: {:gate_closed, missing}}) do
    "state: unverified   verdict: RECOVERY UNVERIFIED   missing_checks: #{length(missing)}"
  end

  def recovery_attestation(%__MODULE__{recovery_verdict: :gate_closed}) do
    "state: unverified   verdict: RECOVERY UNVERIFIED"
  end

  defp format_soak_time(nil), do: ""
  defp format_soak_time(t) when is_struct(t, Tiannara.Soak.TimeAccounting) do
    "validated: #{t.validated_seconds}s   wall: #{t.wall_clock_seconds}s   restarted: #{t.restarted?}"
  end
  defp format_soak_time(other), do: "soak: #{inspect(other)}"
end
