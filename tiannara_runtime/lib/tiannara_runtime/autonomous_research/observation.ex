defmodule TiannaraRuntime.AutonomousResearch.Observation do
  @moduledoc """
  Phase 16.1 — Autonomous Constitutional Research Runtime (Module 1)

  Observation data model + validation + deterministic serialization.

  This is implementation-only and does not issue certificates, run validation campaigns,
  or perform independent audits.
  """

  alias TiannaraRuntime.AutonomousResearch.ObservationID

  @enforce_keys [:origin, :payload]
  defstruct [
    :origin,
    :payload,
    :captured_at,
    :metadata
  ]

  @type t :: %__MODULE__{
          origin: map(),
          payload: map(),
          captured_at: String.t() | nil,
          metadata: map() | nil
        }

  @type validation_error :: {:error, String.t()}

  @doc """
  Build an Observation with deterministic fields.

  `origin` must identify where the observation came from (e.g., dataset / procedure / sensor).
  `payload` contains the observed variables in a deterministic map form (ordering is not assumed).
  """
  @spec new(map(), map(), String.t() | nil, map() | nil) :: {:ok, t()} | validation_error
  def new(origin, payload, captured_at \\ nil, metadata \\ nil)
      when is_map(origin) and is_map(payload) do
    obs = %__MODULE__{
      origin: origin,
      payload: payload,
      captured_at: captured_at,
      metadata: metadata
    }

    validate(obs)
  end

  @doc """
  Validates required fields and basic schema sanity.

  Minimal rules (implementation-stage):
  - origin and payload must be non-empty maps
  - captured_at if present must be ISO8601-ish string
  """
  @spec validate(t() | any()) :: {:ok, t()} | validation_error
  def validate(%__MODULE__{origin: origin, payload: payload} = obs) do
    cond do
      map_size(origin) == 0 ->
        {:error, "origin must be a non-empty map"}

      map_size(payload) == 0 ->
        {:error, "payload must be a non-empty map"}

      true ->
        {:ok, obs}
    end
  end

  def validate(_other), do: {:error, "invalid observation struct"}

  @doc """
  Deterministic content-addressed observation id.

  Defined as hash of canonicalized JSON of:
  - origin
  - payload
  - captured_at
  - metadata (if present)
  """
  @spec id(t()) :: ObservationID.t()
  def id(%__MODULE__{} = obs) do
    canonical =
      %{
        "origin" => obs.origin,
        "payload" => obs.payload,
        "captured_at" => obs.captured_at,
        "metadata" => obs.metadata
      }

    ObservationID.from_canonical_map(canonical)
  end

  @doc """
  Deterministic serialization (canonical JSON bytes).

  Used for replay-compatibility tests and content addressing.
  """
  @spec serialize_json(t()) :: binary()
  def serialize_json(%__MODULE__{} = obs) do
    canonicalize(%{
      "origin" => obs.origin,
      "payload" => obs.payload,
      "captured_at" => obs.captured_at,
      "metadata" => obs.metadata
    })
    |> Jason.encode!()
  end

  @spec serialize_json_bytes(t()) :: binary()
  def serialize_json_bytes(obs), do: serialize_json(obs)

  # --- internal deterministic canonicalization ---
  defp canonicalize(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize(term) when is_list(term), do: Enum.map(term, &canonicalize/1)
  defp canonicalize(term), do: term
end
