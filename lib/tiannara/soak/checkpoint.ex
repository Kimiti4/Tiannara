defmodule Tiannara.Soak.Checkpoint do
  @moduledoc """
  Soak-test checkpoint record.

  Protects SOAK-TEST STATE (not the entire Tiannara runtime). Persists the
  minimal set needed to resume a run without losing validated elapsed time
  or evidence:

      schema_version, soak_run_id, elapsed_seconds, phase, counters,
      discovery_state, health_state, challenge_state, memory_state,
      configuration_hash, runtime_version, created_at, checksum

  Constitutional basis:
    * Safety & Reliability — "Preserve previous stable states",
      "Maintain audit trails", "Support reproducibility".
    * Evidence Before Confidence — elapsed time + evidence must survive a crash.
  """

  @schema_version 1

  @enforce_keys [:soak_run_id, :elapsed_seconds, :phase, :created_at]
  defstruct [
    :schema_version,
    :soak_run_id,
    :elapsed_seconds,
    :phase,
    counters: %{},
    discovery_state: %{},
    health_state: %{},
    challenge_state: %{},
    memory_state: %{},
    configuration_hash: nil,
    runtime_version: nil,
    created_at: nil,
    checksum: nil
  ]

  @type t :: %__MODULE__{}

  def new(fields) do
    base = struct!(__MODULE__, fields)

    base = %{
      base
      | schema_version: @schema_version,
        runtime_version: base.runtime_version || runtime_version()
    }

    %{base | checksum: checksum(base)}
  end

  def schema_version, do: @schema_version

  defp runtime_version do
    "elixir=#{System.version()} otp=#{:erlang.system_info(:otp_release)}"
  end

  @doc "SHA-256 over canonicalized content (checksum field excluded)."
  def checksum(%__MODULE__{} = cp) do
    cp
    |> content_map()
    |> canonicalize()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp content_map(cp) do
    %{
      schema_version: cp.schema_version,
      soak_run_id: cp.soak_run_id,
      elapsed_seconds: cp.elapsed_seconds,
      phase: cp.phase,
      counters: cp.counters,
      discovery_state: cp.discovery_state,
      health_state: cp.health_state,
      challenge_state: cp.challenge_state,
      memory_state: cp.memory_state,
      configuration_hash: cp.configuration_hash,
      runtime_version: cp.runtime_version,
      created_at: cp.created_at
    }
  end

  @doc "Valid iff schema matches, elapsed is sane, and checksum verifies."
  def valid?(%__MODULE__{} = cp) do
    cp.schema_version == @schema_version and
      is_number(cp.elapsed_seconds) and cp.elapsed_seconds >= 0 and
      cp.checksum == checksum(cp)
  end

  def valid?(_), do: false

  def serialize(%__MODULE__{} = cp), do: :erlang.term_to_binary(cp)

  def deserialize(binary) when is_binary(binary) do
    try do
      {:ok, :erlang.binary_to_term(binary)}
    rescue
      _ -> {:error, :undecodable}
    catch
      _, _ -> {:error, :undecodable}
    end
  end

  @doc "Test helper: mutate content so the checksum no longer matches."
  def corrupt!(%__MODULE__{} = cp) do
    %{cp | elapsed_seconds: cp.elapsed_seconds + 1}
  end

  # Order-independent deterministic serialization.
  defp canonicalize(map) when is_map(map) and not is_struct(map) do
    map
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> {k, canonicalize(v)} end)
  end

  defp canonicalize(list) when is_list(list), do: Enum.map(list, &canonicalize/1)
  defp canonicalize(other), do: other
end
